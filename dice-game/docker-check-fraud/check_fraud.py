#!/usr/bin/python3
import sys, os, json, subprocess
import matplotlib
matplotlib.use('Agg')
from matplotlib import pyplot as plt
import numpy as np
from scipy.stats import norm


def main(args_in):
    print ("called with ", args_in)
    try:
        args = json.loads(args_in)
        print ("parsed json ", args_in)
    except:
        return (json.dumps({'success':'False','error':'could not parse args'}))
        
    for msg in args['messages']:
        print ("resolved message: ", msg)
        server_name = "http://192.168.43.167:8080"
        path = msg['value']['billingPath']
        f_name = server_name + path
        b_name = os.path.basename(f_name)[:-4]
        data = np.genfromtxt(f_name,dtype=int)
        N=data.size
        M = 1000
        assert(N % M == 0)

        # calculate N_sigma
        mean = np.mean(data)
        sigma = np.sqrt(35/12)/np.sqrt(N)
        N_sigma = np.round((mean - 3.5)/sigma,2)

        if N_sigma > 5:
            fraud = "discovery"
        elif N_sigma > 4:
            fraud = "evidence"
        elif N_sigma > 3:
            fraud = "candidate"
        else:
            fraud = "undetected"
        if N_sigma > 0:
            p_value = 100*(1-norm.cdf(np.abs(N_sigma)))
        else:
            p_value = 100*norm.cdf(np.abs(N_sigma))

        grid = np.linspace(0,data.size,M+1,dtype=int)[1:]
        mean = np.zeros(M)
        chi2 = np.zeros(M)
        meanf = np.zeros(M)
        chi2f = np.zeros(M)
        bins = np.arange(1,8)
        for i in range(grid.size):    
            x = grid[i]
            h = np.histogram(data[:x],bins)[0]
            mean[i] = np.mean(data[:x])            
            chi2[i] = ((h-x/6)**2).sum()*6/(5*x)

        img_name  = fraud + "--" + b_name + '.png'
        img_path = os.path.join(os.path.dirname(f_name),img_name)

        fig = plt.figure(figsize=(6,9))
        ax = plt.subplot(211)
        plt.plot(grid,mean, label=r'$\bar{m}$')
        plt.title('$\mu$ and $\chi^2$ after $n$ throws')
        plt.ylabel('Mean $\mu$')
        plt.xlabel('$n$ throws')
        plt.ylim((3.475, 3.525))
        plt.axhline(3.5, linestyle='--', color='k')
        plt.axhline(mean[-1], linestyle='-', color='k')
        plt.text(ax.get_xlim()[1], mean[-1]+ 0.002, '$\mu${:1.4f},p={:2.4f}'.format(mean[-1], p_value ), horizontalalignment='right', fontsize = 16)
        plt.grid()
        handles, labels = ax.get_legend_handles_labels()
        ax.legend(handles, labels, loc=1)


        ax1 = plt.subplot(212)
        plt.plot(grid,chi2, label=r'$\chi^2$')
        #plt.title(r'$\chi^2$ after n throws')
        plt.ylabel(r'$\chi^2$')
        plt.xlabel('$n$ throws')
        plt.grid()
        plt.axhline(1, linestyle='-', color='k')
        plt.text(ax.get_xlim()[1], 1.5, "{}: {} $\sigma$".format(fraud, N_sigma), horizontalalignment='right', fontsize = 16)
        handles, labels = ax1.get_legend_handles_labels()
        ax1.legend(handles, labels, loc=2)
        plt.savefig(img_name)
        
        subprocess.call ("curl --upload-file {} {}".format(img_name, img_path), shell=True)
        os.remove(img_name)


    return (json.dumps({"N_sigma":N_sigma, "fraud": fraud, "output":img_path}))


if __name__ == '__main__':
    print (main(sys.argv[1]))


