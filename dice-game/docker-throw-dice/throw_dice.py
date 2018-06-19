#!/usr/bin/python3
import sys, os, json, subprocess
import numpy as np
from datetime import datetime
from scipy.stats import norm

def main(args):
    args = json.loads(args)
    try:
        path = args["path"]
        if not path.endswith("/"):
            path += "/"
    except:
        return json.dumps({'error':'output path must be given'})
    print ("called with: ", json.dumps(args))
    print ("writing to: ", path)

    #data contains N dice throws
    N = 10**6 #number of dice throws
    sigma = np.sqrt(35/12)/np.sqrt(N)
    data = np.random.randint(1,7,N,dtype=int)

    # control_level simulates a varying level of supervision for each dice throw
    control_level = np.random.uniform(0,1,N)

    # 90% of players are fair and do not cheat at all
    # 10% cheat in 1% of dice throws
    is_cheating = np.random.choice([False, True], p = [0.5,0.5])
    cheat_level = 0.015

    # stats for the fair game
    mean_fair = np.mean(data)
    N_sigma_fair = (mean_fair - 3.5)/sigma
    if N_sigma_fair > 0:
        p_fair = 100*(1-norm.cdf(np.abs(N_sigma_fair)))
    else:
        p_fair = 100*norm.cdf(np.abs(N_sigma_fair))

    comment = "# fair game   : p = {0:7.3f}% ~ {1:+4.2f} x sigma".format(p_fair,N_sigma_fair)

    if is_cheating:
        #throwing dice again, if dice shows a one and control_level is low:
        ones = np.where(data==1)
        uncontrolled = np.where(control_level < cheat_level)
        cheating = np.intersect1d(ones, uncontrolled)
        data[cheating] = np.random.randint(1,7,cheating.size)

        # calculate z-value
        mean_unfair = np.mean(data)
        N_sigma_unfair = (mean_unfair - 3.5)/sigma

        # z-value gives likelihood to reach such a deviation from the mean
        if N_sigma_unfair > 0:
            p_unfair = 100*(1-norm.cdf(np.abs(N_sigma_unfair)))
        else:
            p_unfair = 100*norm.cdf(np.abs(N_sigma_unfair))

        comment += "\n# unfair game : p = {0:7.3f}% ~ {1:+4.2f} x sigma".format(p_unfair,N_sigma_unfair)
        comment += "\n# Cheated {} ~ ({})%".format(is_cheating,100*cheating.size/N)
        comment += "\n# mean: {} -> {}".format(mean_fair,mean_unfair)

    time_stamp = datetime.now().strftime("%Y-%m-%d_%H-%M-%S.%f")
    fname = "game-{}.dat".format(time_stamp)
    np.savetxt(fname, data, fmt = '%d')
    #print (comment)
    with open(fname,'a') as f:
        f.write(comment + "\n") 
        f.flush()
        f.close()
    subprocess.call("curl --upload-file {} {}".format(fname, path  + fname), shell=True)
    os.remove(fname)
    return json.dumps({"success":"True","output":path + fname})

if __name__ == '__main__':
    print (main(sys.argv[1]))

