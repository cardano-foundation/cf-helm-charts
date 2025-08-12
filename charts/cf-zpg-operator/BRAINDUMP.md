# Setup minio's cli

```
mc alias set myminio http://localhost:9000 $MINIO_ROOT_USER $MINIO_ROOT_PASSWORD
mc ls myminio/mybucket
```

# List backups from cli

```
envdir "/run/etc/wal-e.d/env" wal-g backup-list
```

# port-forward services

```
kubectl port-forward -n zpg-system svc/postgres-operator-ui 8000:80
kubectl port-forward -n zpg-system svc/minio-console 9001:9001
```

# Doc links

https://postgres-operator.readthedocs.io/en/latest/user/#clone-directly
https://gitlab.com/gitlab-com/runbooks/-/blob/master/docs/patroni/postgresql-backups-wale-walg.md
