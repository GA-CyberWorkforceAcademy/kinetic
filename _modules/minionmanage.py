import salt.utils.network as network
import salt.modules.file as file

__virtualname__ = 'minionmanage'

def __virtual__():
    return __virtualname__

def populate_cache(path):
	pending = file.readdir(path)
	pending.remove('.')
	pending.remove('..')
	return pending

def populate_contoller(path):
	pending = file.readdir(path)
	pending.remove('.')
	pending.remove('..')
	return pending

def populate_controllerv2(path):
	pending = file.readdir(path)
	pending.remove('.')
	pending.remove('..')
	return pending

def populate_storage(path):
	pending = file.readdir(path)
	pending.remove('.')
	pending.remove('..')
	return pending

def populate_compute(path):
	pending = file.readdir(path)
	pending.remove('.')
	pending.remove('..')
	return pending
