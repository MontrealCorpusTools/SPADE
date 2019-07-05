import os
import subprocess

PYTHON_ENV = "python3"

def call_script(script, corpus, f):
    log("STARTING SCRIPT {} WITH CORPUS {}".format(script, corpus), f)
    result = subprocess.run([PYTHON_ENV, script, corpus], stderr=subprocess.STDOUT, stdout=subprocess.PIPE, text=True)
    for l in result.stdout.split("\n"):
        log(l, f)
    return result.returncode

def log(text, f):
    print(text)
    f.write("{}\n".format(text))

corpora = list(filter(lambda x: x.startswith("spade-") \
            and os.path.isdir(x), 
            os.listdir(".")))

with open("run_all_files_log.txt", "w") as f, open("error_log.txt", "w",) as error_f:
    for corpus in corpora:
        return_code = call_script("reset_database.py", corpus, error_f)
        if return_code == 0:
            log("{} imported successfully".format(corpus), f)
        else:
            log("{} did not import successfully".format(corpus), f)
        
    for script in filter(lambda x: x.endswith(".py") and \
            x not in [__file__, "reset_database.py"], \
            os.listdir(".")):
        for corpus in corpora:
            return_code = call_script("reset_database.py", corpus, error_f)
            if return_code == 0:
                log("{} {} ran successfully".format(script, corpus), f)
            else:
                log("{} {} ran unsuccessfully".format(script, corpus), f)
