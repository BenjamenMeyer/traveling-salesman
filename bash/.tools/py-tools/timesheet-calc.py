#!/usr/bin/python3
import argparse
import json
import os
import six
import sys


class BaseTimeSheetCalculator(object):
    """
    Common functionality between the multiple implementations
    """

    def __init__(self):
        self.config = None

        self.load_config()
        self.detect_max_length()

    def run(self, *args, **kwargs):
        raise NotImplementedError('Run Not Implemented by Base')

    def load_config(self):
        user_home = os.environ.get('HOME')
        config_location = None
        config_filename = 'timesheets.json'
        if user_home:
            config_location = '{0}/.config/cws/{1}'.format(user_home, config_filename)
        else:
            config_location = '/etc/cws/{0}'.format(config_filename)

        with open(config_location, 'r') as config_input:
            self.config = json.load(config_input)
            # add section for run-time config options
            self.config['runtime'] = {
                'options': {
                    'max_length': 0,
                    'active_hours': self.config['options']['default_total_hours']
                }
            }

    def detect_max_length(self):
        max_len = 0
        for k in self.config['codes']:
            max_len = max(max_len, len(k['name']))
        self.config['runtime']['options']['max_length'] = max_len

    def get_timecode_config(self, timecode_id):
        for timecode in self.config['codes']:
            if timecode['id'] == timecode_id:
                return timecode

        print('\n*** UNABLE TO FIND CONFIGURATION FOR TIME CODE: {0} ***\n'.format(timecode_id))
        return None


class TimeSheetCalculator(BaseTimeSheetCalculator):
    '''
    This is the original version which was extremely simplified; however,
    keeping track of hours/day and validating totals was near impossible.
    This is kept around for historical record keeping so the old timesheet files
    do not need to get updated to the new format.

    Comments were added to be able to add notes but it wasn't sufficient.

    NOTE: The timesheet version is implied as the `version` keyword is not supported.

    Timesheet input:

        {
            "comment name": "comment value - key just have to have 'comment' in it",
            "job_id": <hours>
        }
    '''

    def __init__(self):
        super(TimeSheetCalculator, self).__init__()

    def run(self, time_values):
        self.scan_option_adjustments(time_values)
        self.detect_active_hours(time_values)
        self.display_active_timecodes(time_values)
        self.display_available_codes(time_values)
        self.print_comments(time_values)

    def scan_option_adjustments(self, tv):
        for k, v in six.iteritems(tv):
            if 'option' in k.lower():
                # option adjustment
                if 'total_hours' in k.lower():
                    print("*** Adjusting Default Active Hours from {0} to {1}".format(self.config['runtime']['options']['active_hours'], v))
                    self.config['runtime']['options']['active_hours'] = v

    def get_timecode_config(self, timecode_id):
        if 'comment' in timecode_id.lower():
            # skipping - comment block
            return None

        if 'option' in timecode_id.lower():
            # skipping - comment block
            return None

        return super(TimeSheetCalculator, self).get_timecode_config(timecode_id)

    def detect_active_hours(self, tv):
        for k, v in six.iteritems(tv):
            if v:
                k_config = self.get_timecode_config(k)
                if k_config is None:
                    continue

                if not k_config['counts_on_40']:
                    self.config['runtime']['options']['active_hours'] -= v

    def print_comments(self, tv):
        comments = []

        for k,v in six.iteritems(tv):
            if 'comment' in k:
                comments.append(v)

        if comments:
            print("\nComments:")
            for c in comments:
                print("\t{0}".format(c))

    def display_active_timecodes(self, tv):
        max_len = self.config['runtime']['options']['max_length']
        max_len += 2
        calc_total_hours = 0
        calc_total_percentage = 0
        for k in sorted(tv.keys()):
            k_config = self.get_timecode_config(k)
            if k_config is None:
                continue

            v = tv[k]
            p = (float(v) / self.config['runtime']['options']['active_hours']) * 100.0
            if k_config['counts_on_40']:
                calc_total_percentage += p
                calc_total_hours += v
            else:
                p = 0

            if v:
                print(
                    "{0:<80}{1:>8}{2:>9}{3}".format(
                        k_config['name'],
                        '{0:2,.2f}'.format(v),
                        '{0:2,.2f}'.format(p),
                        '' if k_config['active'] else '\tWARNING IN ACTIVE CODE IN USE'
                    )
                )

        print(
            "\n{0:>73}Total: {1:>8}{2:>9}".format(
                '',
                '{0:2,.2f}'.format(calc_total_hours),
                '{0:2,.2f}'.format(calc_total_percentage)
            )
        )

        if calc_total_hours != self.config['runtime']['options']['active_hours']:
            print('\nWARNING: Total Hours DO NOT MATCH\n')
            print('\tCalculated Total: {0:2,.2f}'.format(calc_total_hours))
            print('\t    Active Total: {0:2,.2f}'.format(self.config['runtime']['options']['active_hours']))

    def display_available_codes(self, tv):
        print("\nAvailable Time Codes:")
        for k in sorted(tv.keys()):
            if not tv[k]:
                k_config = self.get_timecode_config(k)
                if k_config is None:
                    continue

                if k_config['active']:
                    print("\t{0} (id: {1})".format(k_config['name'], k))

class TimeSheetCalculator2(BaseTimeSheetCalculator):
    '''
    This version upgrades the original functionality by tracking by-day instead
    of overall thereby making it easy to validate hours/day. Moreover, it drops
    the support for comments while adding the ability to provide descriptions
    for each day's work time. Each day is a simple list of job codes and time.

    Some of the detected information that was previously scanned for is now in
    its own section, and an explicit version section was added.

    Timesheet input:

        {
            "version": "2",
            "dates": {
                "<date>": {
                    "jobs": [
                        {
                            "id": <job_id>,
                            "hours": <hours>,
                            "description": "comment value"
                        }
                    ]
                },
            },
            "options": {
                "total_hours": <total>,
            }
        }
    '''

    def __init__(self):
        super(TimeSheetCalculator2, self).__init__()
        self.time_data = {}

    def run(self, json_doc):
        self.apply_timesheet_options(json_doc)
        self.detect_active_hours(json_doc)
        self.calculate_hours(json_doc)
        self.display()
        self.display_available_codes()
        self.display_date_summaries()

    def apply_timesheet_options(self, json_doc):
        for option_name, option_value in six.iteritems(json_doc['options']):
            if option_name.lower() == 'total_hours':
                print("*** Adjusting Default Active Hours from {0} to {1}".format(self.config['runtime']['options']['active_hours'], option_value))
                self.config['runtime']['options']['active_hours'] = option_value

    def detect_active_hours(self, json_doc):
        for job_date, data in six.iteritems(json_doc['dates']):
            for jobs_on_date in data['jobs']:
                if jobs_on_date['hours']:
                    job_config = self.get_timecode_config(jobs_on_date['id'])
                    if job_config is None:
                        continue

                    if not job_config['counts_on_40']:
                        self.config['runtime']['options']['active_hours'] -= jobs_on_date['hours']

    def calculate_hours(self, json_doc):
        self.time_data = {
            'total_hours': 0,
            'total_percentage': 0.0,
            'date_hours': {},
            'job_hours': {}
        }
        for job_date, data in six.iteritems(json_doc['dates']):
            if job_date not in self.time_data:
                self.time_data['date_hours'][job_date] = {
                    'total_hours': 0,
                    'jobs': []
                }
            for jobs_on_date in data['jobs']:
                job_id = jobs_on_date['id']
                job_config = self.get_timecode_config(job_id)
                if job_config is None:
                    continue

                hours = jobs_on_date['hours']
                if job_config['counts_on_40']:
                    self.time_data['total_hours'] += hours

                self.time_data['date_hours'][job_date]['total_hours'] += hours
                self.time_data['date_hours'][job_date]['jobs'].append(jobs_on_date)

                if job_id not in self.time_data['job_hours']:
                    self.time_data['job_hours'][job_id] = {
                        'hours': hours,
                        'percentage': 0.0
                    }
                else:
                    self.time_data['job_hours'][job_id]['hours'] += hours

        for job_id, job_hours in six.iteritems(self.time_data['job_hours']):
            job_config = self.get_timecode_config(job_id)
            if job_config is None:
                continue

            if job_config['counts_on_40']:
                job_hours['percentage'] = (
                    (float(job_hours['hours']) / self.config['runtime']['options']['active_hours']) * 100.0
                )

                self.time_data['total_percentage'] += job_hours['percentage']

    def display(self):
        for job_id in sorted(self.time_data['job_hours'].keys()):
            job_config = self.get_timecode_config(job_id)
            if job_config is None:
                continue

            v = self.time_data['job_hours'][job_id]['hours']
            p = self.time_data['job_hours'][job_id]['percentage']
            if v:
                print(
                    "{0:<80}{1:>8}{2:>9}{3}".format(
                        job_config['name'],
                        '{0:2,.2f}'.format(v),
                        '{0:2,.2f}'.format(p),
                        '' if job_config['active'] else '\tWARNING IN ACTIVE CODE IN USE'
                    )
                )

        print(
            "\n{0:>73}Total: {1:>8}{2:>9}".format(
                '',
                '{0:2,.2f}'.format(self.time_data['total_hours']),
                '{0:2,.2f}'.format(self.time_data['total_percentage'])
            )
        )

        if self.time_data['total_hours'] != self.config['runtime']['options']['active_hours']:
            print('\nWARNING: Total Hours DO NOT MATCH\n')
            print('\tCalculated Total: {0:2,.2f}'.format(self.time_data['total_hours']))
            print('\t    Active Total: {0:2,.2f}'.format(self.config['runtime']['options']['active_hours']))

    def display_available_codes(self):
        print("\nAvailable Time Codes:")
        all_job_ids = [
            time_code['id']
            for time_code in self.config['codes']
        ]

        for job_id in self.time_data['job_hours'].keys():
            if self.time_data['job_hours'][job_id]['hours']:
                if job_id in all_job_ids:
                    all_job_ids.remove(job_id)

        for job_id in sorted(all_job_ids):
            job_config = self.get_timecode_config(job_id)
            if job_config is None:
                continue

            if job_config['active']:
                print("\t{0} (id: {1})".format(job_config['name'], job_id))

    def display_date_summaries(self):
        print("\nDate Summary:")
        for date_key in sorted(self.time_data['date_hours'].keys()):
            data = self.time_data['date_hours'][date_key]
            print("\t{0} - Total hours: {1}".format(date_key, data['total_hours']))
            for job_on_date in data['jobs']:
                job_config = self.get_timecode_config(job_on_date['id'])
                print(

                    #"{0:<80}{1:>8}{2:>9}{3}".format(
                    '\t\t{0:<80}{1:>8} "{2:}"'.format(
                        job_config['name'],
                        job_on_date['hours'],
                        job_on_date['description']
                    )
                )

def main():
    argument_parser = argparse.ArgumentParser(
        description="Time Sheet Calculator"
    )
    argument_parser.add_argument(
        '--time-sheet', '-ts',
        default=None,
        type=argparse.FileType('r'),
        required=True,
        help='JSON file containing a dictionary of time code ids and hours worked'
    )
    arguments = argument_parser.parse_args()
    try:
        json_doc = json.load(arguments.time_sheet)
    except:
        print('Invalid JSON input document')
        return 2

    # input document versions matching up to the class managing it
    tsc_versions = {
        '1': TimeSheetCalculator,
        '2': TimeSheetCalculator2
    }

    try:
        # version 1 document doesn't have the version field in it
        json_doc_version = json_doc['version']
    except KeyError:
        json_doc_version = '1'

    try:
        tsc_used = tsc_versions[json_doc_version]
    except KeyError:
        print(
            "Unknown input document version {0}. Supported versions: {1}".format(
                json_doc_version,
                tsc_versions.keys()
            )
        )
        return 1

    tsc = tsc_used()
    tsc.run(json_doc)

    return 0

if __name__ == "__main__":
    sys.exit(main())
