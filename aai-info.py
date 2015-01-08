#!/usr/bin/env python
# -*- coding: UTF-8 -*-
# by LINDAT/CLARIN dev team (http://lindat.cz, ok, ak, jm)
# @2014

"""
    Show statistics and interesting information from
    shibd (debug) logs.
"""
import codecs
import glob
import os
import sys
import getopt
import urllib
from datetime import datetime
import re

try:
    from dateutil import parser as dateparser
except:
    print "Install dateutil python package"
    sys.exit( 1 )
try:
    from lxml import etree
except:
    print "Install lxml python package"
    sys.exit( 1 )

#============================================
# settings
#============================================

settings = {

    "federations": {
        "clarinSPF": "https://infra.clarin.eu/aai/prod_md_about_spf_idps.xml",
        "eduGain": "http://mds.edugain.org",
        "eduID": "https://metadata.eduid.cz/entities/eduid+idp",
    },

    "encoding": "utf-8",

    "xslt.atts": { "atts": "http://lindat.cz/attributes"},

    "idps": {},

    #
    "xsl": "atts2html.xsl",
    "xsd": "attributes.xsd",
    "attribute-map_file": os.path.join(
        os.path.dirname(os.path.abspath(__file__)),
        "shibboleth/attribute-map.xml" ),

    # store xml nodes
    "nodes": {

    },

    #
    "fetch_metadata": True,
    #"fetch_metadata": False,

    "missing_metadata_file": os.path.join(
        os.path.dirname(os.path.abspath(__file__)),
        "missing.idps.xml" ),

    # info
    "info": {
        "skipped": (
            # 2014-11-02 01:34:21 DEBUG Shibboleth.AttributeExtractor.XML [644]: skipping unmapped NameID with format (urn:oasis:names:tc:SAML:2.0:nameid-format:transient)
            re.compile( ".* skipping unmapped (.*)$" ),
        ),
        "removed": (
            # 2014-11-02 01:34:21 WARN Shibboleth.AttributeFilter [644]: removed value at position (1) of attribute (affiliation) from (https://cas.cuni.cz/idp/shibboleth)
            re.compile( ".* removed value at (.*)$" ),
        ),
    }
}


#============================================
# helpers
#============================================

def parse_entity_descriptor(metadata_url):
    """
        Get entityIDs for the specified federation metadata url
    """
    entitySet = set( )
    doc = etree.parse( urllib.urlopen( metadata_url ) )
    entities = doc.xpath( "//*[local-name()='EntityDescriptor']" )
    for entity in entities:
        entitySet.add( entity.attrib["entityID"] )
    return entitySet


def create_info_xml(env, last_access, out_file):
    """
        Create new information file.
    """
    doc = etree.XML( """
<?xml-stylesheet href="%s" type="text/xsl"?>
    <atts:parsedLog xmlns:atts="%s"
        xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xsi:schemaLocation="%s" />
        """ % (env["xsl"], env["xslt.atts"]["atts"], env["xsd"]) )

    root = etree.QName( doc )

    # lastAccess
    la_node = etree.Element( etree.QName( root, "lastAccess" ) )
    la_node.text = unicode( last_access )
    doc.append( la_node )

    for key in (
            "idps",
            "info-skipped",
            "info-removed",
            "attribute-map",
    ):
        node = etree.Element( etree.QName( root, key ) )
        doc.append( node )

    with codecs.open( out_file, mode="wb") as fout:
        fout.write( etree.tostring(
            doc.getroottree( ),
            xml_declaration=True,
            pretty_print=True,
            encoding=env["encoding"].upper() )
        )


def parse_info_xml(env, info_xml_file):
    namespaces = env["xslt.atts"]

    def parse_doc_and_time():
        parser = etree.XMLParser(remove_blank_text=True)
        d = etree.parse( info_xml_file, parser )
        la = d.find( "atts:lastAccess", namespaces=namespaces )
        return d, la

    # parse and get basic info, in case of error recreate
    try:
        doc, last_accessed_node = parse_doc_and_time()
        last_accessed_date = dateparser.parse( last_accessed_node.text )
    except:
        last_access = unicode(datetime.now())
        create_info_xml( env, last_access, info_xml_file )
        doc, last_accessed_node = parse_doc_and_time()
        last_accessed_date = datetime.min

    env["nodes"]["last_accessed"] = last_accessed_node

    idps_node = doc.find( "atts:idps", namespaces=namespaces )
    env["nodes"]["idps"] = idps_node

    for info_key in ( "info-skipped", "info-removed" ):
        info_node = doc.find( "atts:%s" % info_key, namespaces=namespaces )
        env["nodes"][info_key] = info_node

    seen_idps = {}
    for ids in env["nodes"]["idps"].findall(
            "atts:idp", namespaces=namespaces ):
        seen_idps[ids.attrib["entityId"]] = ids

    return etree.QName(doc.getroot()), doc, seen_idps, last_accessed_date


def create_idp_xml( env, root, idp ):
    """
        Create xml representation of an idp.
    """
    idp_node = etree.Element( etree.QName( root, "idp" ) )
    idp_node.attrib["entityId"] = idp
    for (source, nf_idps) in env["idps"].items():
        if idp in nf_idps:
            idp_node.attrib[source] = "true"
    idp_node.append( etree.Element( etree.QName( root, "seenAttrLists" ) ) )
    return idp_node


def iter_valid_assertion_blocks( in_files_glob, ignore_before_date, line_ftor=None ):
    """
        Parse the log and return xml containing all required information
    """
    start_read_assertion_re = re.compile( "(decrypted Assertion:)|(decoded SAML message:)" )
    end_read_assertion_re = re.compile( "</.*Assertion>" )
    log_date_re = re.compile( r"\d{4}-\d{2}-\d{2}" )

    def int_cmp( a, b ):
        try:
            int( a[-1] )
        except:
            return -1
        try:
            int( b[-1] )
        except:
            return 1
        last_int_a = int(a.split(".")[-1])
        last_int_b = int(b.split(".")[-1])
        return last_int_a - last_int_b

    files = []
    for in_file_glob in in_files_glob:
        files += glob.glob(in_file_glob)

    # loop through sorted files (oldest one first)
    for in_file in sorted( files, cmp=int_cmp, reverse=True ):
        print "Working on [%s]" % in_file
        with codecs.open( in_file, "rb" ) as line_iter:
            for line in line_iter:

                # already done logs
                try:
                    log_line_date = dateparser.parse( line[0:19] )
                except:
                    continue
                if log_line_date < ignore_before_date:
                    continue

                # collect line information?
                if line_ftor is not None:
                    line_ftor( in_file, line )

                match = start_read_assertion_re.search( line )
                if not match:
                    continue

                xml = line[match.end():]
                if not end_read_assertion_re.search( line ):
                    line = next( line_iter )
                    while True:
                        xml += line
                        match = end_read_assertion_re.search( line )
                        # proper ending
                        if match:
                            break
                        # another request
                        if "EncryptedAssertion" in line:
                            break
                        if log_date_re.match( line ):
                            break
                        # try next line
                        line = next(line_iter)

                if not match:
                    continue

                yield xml, log_line_date


def update_idp_with_seen_attribute(env, root, seen_idp_node, current_attr, seen_date):
    """
        Found new idp attribute so add it to seen with proper attributes.
    """
    namespaces = env["xslt.atts"]
    seen_idp = seen_idp_node.find(
        "atts:seenAttrLists", namespaces=namespaces )
    attr_list = etree.SubElement(
        seen_idp, etree.QName( root, "list" ) )
    seen_first = etree.SubElement(
        attr_list, etree.QName( root, "firstSeen" ) )
    seen_last = etree.SubElement(
        attr_list, etree.QName( root, "lastSeen" ) )
    seen_first.text = unicode( seen_date )
    seen_last.text = unicode( seen_date )

    for cur in current_attr:
        attrs = [ (x, cur.attrib[x]) for x in ["Name", "FriendlyName", "NameFormat"]
                  if x in cur.attrib ]
        attr = etree.SubElement(attr_list, etree.QName( root, "attr" ) )
        for (k, v) in attrs:
            n = etree.SubElement( attr, etree.QName( root, k ) )
            n.text = v


def add_missing( env, out_file ):
    """
        Add missing attribute idps which were in lost logs.
    """
    if not os.path.exists(env["missing_metadata_file"]):
        return
    with codecs.open( out_file, mode="rb", encoding=env["encoding"] ) as fin:
        xml = fin.read()
    with codecs.open( env["missing_metadata_file"], mode="rb", encoding=env["encoding"] ) as fin:
        missing = fin.read()
    xml = xml.replace( u"</atts:idps>", u"%s</atts:idps>" % missing )
    with codecs.open( out_file, mode="w", encoding=env["encoding"] ) as fout:
        fout.write( xml )


def collect_line_info( env, d, filename, line ):
    """
        Get more information
    """
    if not filename.endswith( "shibd.log" ):
        return
    #
    for k, vs in env["info"].iteritems():
        k = "info-%s" % k
        for v in vs:
            m = v.search( line )
            if m:
                if k not in d:
                    d[k] = []
                d[k].append( m.group(1) )
                break


#============================================
# parsing
#============================================

def parse_shibboleth_logs(env, in_files_glob, out_file):
    """

    """
    root, doc, seen_idps, last_accessed_date = parse_info_xml(env, out_file)
    namespaces = env["xslt.atts"]
    info_d = {}

    for xml, log_line_date in iter_valid_assertion_blocks(
            in_files_glob,
            last_accessed_date,
            lambda f, l: collect_line_info( env, info_d, f, l ) ):
        try:
            assertion_xml = etree.XML( xml.strip( ) )
        except:
            # can happen when the logs are incomplete or invalid (multiple logings?)
            continue
        issuer = assertion_xml.xpath( "//*[local-name()='Issuer']" )[0]
        idp = issuer.text

        if not idp in seen_idps:
            seen_idp_node = create_idp_xml( env, root, idp )
            seen_idps[idp] = seen_idp_node
            env["nodes"]["idps"].append( seen_idp_node )
        seen_idp_node = seen_idps[idp]

        last_seen_names = seen_idp_node.xpath(
            "./atts:seenAttrLists/atts:list[last()]/atts:attr/atts:Name/text()",
            namespaces=namespaces
        )
        current_attr = assertion_xml.xpath( "//*[local-name()='Attribute']" )
        new_name = False
        for not_seen in current_attr:
            if not_seen.attrib["Name"] not in last_seen_names:
                new_name = True
                break

        if new_name:
            update_idp_with_seen_attribute(
                env, root, seen_idp_node, current_attr, log_line_date)

        else:
            last_seen = seen_idp_node.xpath(
                "//atts:list[last()]/atts:lastSeen", namespaces=namespaces )[0]
            last_seen.text = unicode( log_line_date )

    # fill out date and attributes
    env["nodes"]["last_accessed"].text = unicode( datetime.now( ) )
    node = doc.find( "atts:attribute-map", namespaces=namespaces )
    if os.path.exists(env["attribute-map_file"]):
        with codecs.open( env["attribute-map_file"], mode="r", encoding=env["encoding"]) as fin:
            node.text = fin.read()
    else:
        node.text = "cannot find [%s]" % env["attribute-map_file"]

    # fill out info
    for k, vs in info_d.iteritems():
        info_node = env["nodes"][k]
        for v in vs:
            n = etree.SubElement( info_node, etree.QName( root, "value" ) )
            n.text = v

    xml_output = etree.tostring(
        doc,
        pretty_print=True,
        xml_declaration=True,
        encoding=env["encoding"].upper()
    )
    with codecs.open( out_file, mode="w" ) as fout:
        fout.write( xml_output )


def main(env, argv):
    try:
        opts, _1 = getopt.getopt(
            argv, "hi:o:c:d", ["help", "in=", "out="] )
    except getopt.GetoptError:
        show_help()
        sys.exit( 1 )

    in_files = []
    out_file = None
    for opt, arg in opts:
        if opt == '-h':
            show_help()
            sys.exit()
        elif opt in ("-i", "--in"):
            in_files.append( arg )
        elif opt in ("-o", "--out"):
            out_file = arg

    if 0 == len(in_files) or out_file is None:
        show_help( )
        sys.exit( 1 )

    # get the list of IDPs from different sources
    if env["fetch_metadata"]:
        for (source, metadata_url) in settings["federations"].items( ):
            env["idps"][source] = parse_entity_descriptor( metadata_url )

    # parse the log to find out new IDPs and changes in their attribute set
    parse_shibboleth_logs( env, in_files, out_file )
    # this should be added only once and then delete/rename the file
    add_missing( env, out_file )


def show_help():
    """
        Print help message.
    """
    print "usage: aai-info.py -i shibd.log -o attributes.xml [--help|-h] [--create|-c] [--debug|-d]"
    print "Reads the attributes sent by IDPs from shibd.log and adds them to the xml file (creates it if necessary)"


if __name__ == "__main__":
    main( settings, sys.argv[1:] )
