from ansiblelint import AnsibleLintRule

class TaskManyArgs(AnsibleLintRule):
    id = 'E303'
    shortdesc = 'Use ":" YAML format when arguments are over 3'
    description = ''
    tags = ['task']

    def match(self, file, text):
        text = text.lstrip()
        if text.startswith('command:') or text.startswith('name:') or 'lookup(' in text:
            return False

        count = len([part for part in text.split(" ") if "=" in part])
        return count > 3
