# ASAP (Automated Single-Cell Analysis Portal) web application

## History and context

This is the second iteration of ASAP. It implements [this interface](https://asap.epfl.ch).
It comes after implementing a [first version](https://asap-old.epfl.ch) [[github link](https://github.com/DeplanckeLab/asap_old)]
We started developing in parallel a new version of ASAP using rails 8 [[github](https://github.com/DeplanckeLab/asap_web)]

## Goals with this version

We wanted with this version of ASAP:
   - to offer more flexibility on the order of analysis steps to run.
   - to allow a total reproducibility of the analyses to support their publication. Each project comes with a script to be able to reproduce the analysis locally, using the according asap_run docker image.
   - to enable collaborative annotations of single-cell datasets

## What we do not provide with this version

We didn't plan to provide a support to install the application on other systems.
It's actually quite dependent on out local architecture (regarding computing and storage) and to adapt the code to different infrasturcture would require some work.
As we received a few requests to install locally the web server, we plan to provide this feature with the next version of ASAP.

## Job daemon

```
docker-compose exec website bash
nohup rails exec_runs --trace > log/exec_runs.log &
```

