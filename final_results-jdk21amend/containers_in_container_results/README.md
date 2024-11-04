# Warning!
containers_in_container_DACAPO were exceptionaly UNSTABLE
when run first time, they simply did not finished a single run.
When run second time, they produced the resutls which are commited.

However the results seems to be incoplete - many tasks kave never finished, and jsut for soem reason, the tollchan continued to run.

```
find  containers_in_container_DACAPO/ | grep summa | wc -l >> README.md
cat `find  containers_in_container_DACAPO/ | grep summa ` | grep geom | wc -l >> README.md
```

there is 92 sumamry files
but only 32 of them have geom value

It iiuc reflects the real crash rate. Runs wihtout geom should be removed
