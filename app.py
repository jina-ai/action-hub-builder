import json
import os
import pathlib

from jina.docker.hubio import HubIO
from jina.helper import get_now_timestamp, get_full_version
from jina.logging import default_logger
from jina.main.parser import set_hub_base_parser, set_hub_build_parser


def get_parser():
    parser = set_hub_base_parser()
    parser.add_argument('target', type=str,
                        help='the directory path of target Pod image, where manifest.yml and Dockerfile located')
    parser.add_argument('--fail-fast', action='store_true', default=False,
                        help='when set to true, cancels all build jobs if any one fails.')
    parser.add_argument('--summary', type=str, default=f'build-{get_now_timestamp()}.json',
                        help='path of the build summary')
    parser.add_argument('--prune-image', action='store_true', default=False,
                        help='prune image after each build, this often saves disk space')
    parser.add_argument('--dry-run', action='store_true', default=False,
                        help='only check path and validility, no real building')

    return parser


def main(args):
    all_targets = list(
        set(os.path.abspath(p.parent) for p in pathlib.Path(args.target).absolute().glob('**/manifest.yml')))
    all_targets.sort()
    default_logger.info(f'{len(all_targets)} targets to build')
    info, env_info = get_full_version()
    import docker
    client = docker.APIClient(base_url='unix://var/run/docker.sock')
    summary = {
        'builder_args': vars(args),
        'num_tasks': len(all_targets),
        'start_time': get_now_timestamp(),
        'host_info': {
            'jina': info,
            'jina_envs': env_info,
            'docker': client.info(),
        },
        'tasks': []
    }
    parser = set_hub_build_parser()
    for t in all_targets:
        p = parser.parse_args([t, '--pull'])
        if args.dry_run:
            s = HubIO(p).dry_run()
        else:
            s = HubIO(p).build()

        s['path'] = t
        summary['tasks'].append(s)
        if not s['is_build_success']:
            default_logger.error(f'❌ {t} fails to build')
            if args.fail_fast:
                break
        else:
            default_logger.success(f'✅ {t} is successfully built!')
        if args.prune_image:
            default_logger.info('deleting unused images')
            client.prune_images()

    with open(args.summary, 'w') as fp:
        json.dump(summary, fp)

    failed = [t for t in summary['tasks'] if not t['is_build_success']]
    if failed:
        default_logger.warning(f'{len(failed)}/{len(all_targets)} failed to build')
        for t in failed:
            default_logger.error(f'{t["path"]}\t{t["exception"]}')


if __name__ == '__main__':
    a = get_parser().parse_args()
    main(a)
