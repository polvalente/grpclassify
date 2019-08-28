import xml.etree.ElementTree as ET
import sys

# usage: python gt_parser <xml file> <parsed file prefix> <jpg file prefix> <frame number leading zeros>
tree = ET.parse(sys.argv[1])

# fps = 25 spf = 1/fps
spf = 0.04


def format_frame_number(n):
    return ("%0" + sys.argv[4] + "d") % n


def parse_frame(frame):
    frame_number = int(frame.attrib['number'])
    object_list = frame.find('objectlist')
    number_of_people = len(list(object_list))
    timestamp = frame_number * spf
    filename = sys.argv[3] + format_frame_number(frame_number) + '.jpg'
    return {'id': frame_number, 'timestamp': timestamp, 'num_people': number_of_people, 'filename': filename}


dataset = tree.getroot()
frames = [parse_frame(f) for f in dataset]
with open('parsed_gt/%s.csv' % sys.argv[2], 'w+') as f:
    f.write('FrameNumber,Timestamp,NumPeople,Filename\n')
    for frame in frames:
        f.write('%d,%.03f,%d,"%s"\n' %
                (frame['id'], frame['timestamp'], frame['num_people'], frame['filename']))
