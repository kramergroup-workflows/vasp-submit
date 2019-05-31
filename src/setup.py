from distutils.core import setup
from distutils.command.bdist_dumb import bdist_dumb
from setuptools import setup, find_namespace_packages


class custom_bdist_dumb(bdist_dumb):

    def reinitialize_command(self, name, **kw):
        cmd = bdist_dumb.reinitialize_command(self, name, **kw)
        if name == 'install':
            cmd.install_lib = '/'
        return cmd

if __name__ == '__main__':
    setup(
        # our custom class override
        cmdclass = {'bdist_dumb': custom_bdist_dumb},
        name='vasp-driver',
        py_modules = ['__main__'],
        packages = find_namespace_packages(include=['casm.*'])
    )