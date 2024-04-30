#!/usr/bin/env python3
# auto_pipeline_runner


# [[file:docs/auto_pipeline_runner.org::*auto_pipeline_runner][auto_pipeline_runner:1]]
import requests
import os
import subprocess
import argparse
from itertools import compress
# auto_pipeline_runner:1 ends here

# [[file:docs/auto_pipeline_runner.org::*auto_pipeline_runner][auto_pipeline_runner:2]]
def check_syncthing_completion(url, api_key):
    headers = {"X-API-Key": api_key}
    response = requests.get(url, headers=headers).json()
    if response and response["completion"] == 100 and response["needItems"] == 0:
        return True
# auto_pipeline_runner:2 ends here

# [[file:docs/auto_pipeline_runner.org::*auto_pipeline_runner][auto_pipeline_runner:3]]
def start_run(dir_name, script_path, fastq_dir_base, result_dir_base):
    if dir_name:
        input_dir = os.path.join(fastq_dir_base, dir_name)
        output_dir = os.path.join(result_dir_base, dir_name)
        command = f"ts -L {dir_name} {script_path} --input_dir {input_dir} --output_dir {output_dir}"
        subprocess.check_output(command, shell=True)
# auto_pipeline_runner:3 ends here

# [[file:docs/auto_pipeline_runner.org::*auto_pipeline_runner][auto_pipeline_runner:4]]
def get_new_dirs(fastq_dir_base, result_dir_base):
    processing_dirs = subprocess.check_output("ts -l | sed 1d | grep -oP '(?<=\[)[^\]]+' || echo ''", shell=True).decode("utf-8").split()
    new_dirs = set(os.listdir(fastq_dir_base)) - set(os.listdir(result_dir_base)) - set(processing_dirs)
    return new_dirs
# auto_pipeline_runner:4 ends here



# TODO: break and error on ongoing sync

# [[file:docs/auto_pipeline_runner.org::*auto_pipeline_runner][auto_pipeline_runner:5]]
def main():
    parser = argparse.ArgumentParser(description="Syncthing Completion Checker")
    parser.add_argument("--url", help="URL of the Syncthing API")
    parser.add_argument("--api_key", help="Syncthing API key")
    parser.add_argument("--script_path", help="Path to the Nextflow script", required = True)
    parser.add_argument("--input_dir_base", help="Base directory for input directories", required = True)
    parser.add_argument("--result_dir_base", help="Base directory for output directories", required = True)

    args = parser.parse_args()

    url_provided = args.url is not None
    key_provided = args.api_key is not None

    check_syncthing = url_provided and key_provided
    print("check syncthing required: ",check_syncthing)

    if check_syncthing:
        if check_syncthing_completion(args.url, args.api_key):
            print("check syncthing completion: ",check_syncthing)
            new_dirs = get_new_dirs(args.input_dir_base, args.result_dir_base)
        else:
            print("ongoing sync")
    else:
        new_dirs = get_new_dirs(args.input_dir_base, args.result_dir_base)

    modifications = list(map(
        lambda new_dir: bool(
            subprocess.check_output(
                f"./check_file_modification.sh --dir {os.path.join(args.input_dir_base,new_dir)} --interval 3",
                shell=True
            ).decode("utf-8")
        ),
        new_dirs
    ))

    for dir_name in compress(new_dirs, modifications):
        start_run(dir_name, args.script_path, args.input_dir_base, args.result_dir_base)
# auto_pipeline_runner:5 ends here

# [[file:docs/auto_pipeline_runner.org::*auto_pipeline_runner][auto_pipeline_runner:6]]
if __name__ == "__main__":
    main()
# auto_pipeline_runner:6 ends here
