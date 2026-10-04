# mongo

### After installing a new ssd

```
sudo bash -c "$(curl -fsSL https://raw.githubusercontent.com/moongooseorg/infra-mongo/main/setup-ssd.sh)"
```

To specify the disk explicitly instead of auto-detecting:

### Before deploying
Ensure your github org has the following secrets set to whatever you want

MONGO_ROOT_USERNAME
MONGO_ROOT_PASSWORD