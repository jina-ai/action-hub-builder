import json
import os
import pathlib

from jina.docker.hubio import HubIO
from jina.helper import get_now_timestamp, get_full_version
from jina.logging import default_logger
from jina.main.parser import set_hub_build_parser


def get_parser():
    parser = set_hub_build_parser()
    parser.add_argument('--fail-fast', action='store_true', default=False,
                        help='when set to true, cancels all build jobs if any one fails.')
    parser.add_argument('--summary', type=str, default=f'build-{get_now_timestamp()}.json',
                        help='path of the build summary')
    return parser


def main(args):
    all_targets = list(
        set(os.path.abspath(p.parent) for p in pathlib.Path(args.path).absolute().glob('**/manifest.yml')))
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
    for t in all_targets:
        args.path = t
        args.pull = True
        args.test_uses = True
        s = HubIO(args).build()
        s['path'] = t
        summary['tasks'].append(s)
        if not s['is_build_success']:
            default_logger.error(f'❌ {t} fails to build')
            if args.fail_fast:
                break
        else:
            default_logger.success(f'✅ {t} is successfully built!')

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
