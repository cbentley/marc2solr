<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet exclude-result-prefixes="xs lbi" version="2.0" xmlns:lbi="http://www.lbi.org/"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
    <!--
        *
        * Transform OAI XML into Solr XML
        * Author: Chris Bentley
        *
    -->
    <xsl:output encoding="UTF-8" indent="yes" method="xml" />
    <xsl:strip-space elements="*" />
    <!-- A mapping between field numbers and names -->
    <xsl:variable name="lbi:metadata_fields">
        <metadata_field key="094">call_number</metadata_field>
        <metadata_field key="100">artist</metadata_field>
        <metadata_field key="110">artist</metadata_field>
        <metadata_field key="245">title</metadata_field>
        <metadata_field key="246">title_varying_form</metadata_field>
        <metadata_field key="260">publication</metadata_field>
        <metadata_field key="264">publication</metadata_field>
        <metadata_field key="300">physical_description</metadata_field>
        <metadata_field key="490">series</metadata_field>
        <metadata_field key="500">general_note</metadata_field>
        <metadata_field key="520">summary</metadata_field>
        <metadata_field key="545">biog_hist_data</metadata_field>
        <metadata_field key="583">catalog_code</metadata_field>
        <metadata_field key="600">subject_personal_name</metadata_field>
        <metadata_field key="630">subject_topical_term</metadata_field>
        <metadata_field key="650">subject_topical_term</metadata_field>
        <metadata_field key="651">subject_geographic_name</metadata_field>
        <metadata_field key="655">genre</metadata_field>
        <metadata_field key="700">artist_added</metadata_field>
        <metadata_field key="710">artist_added</metadata_field>
        <metadata_field key="773">host_item</metadata_field>
        <metadata_field key="856">digital_object_url</metadata_field>
    </xsl:variable>
    <xsl:variable name="save_dir">
        <xsl:choose>
            <xsl:when
                test="starts-with(document-uri(/), 'file:/C:')
                or starts-with(document-uri(/), 'file:/J:')
                or starts-with(document-uri(/), 'file:/K:')">
                <xsl:text />
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>/home/leobaeck/scripts/lbi_art2/</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <!-- List of fields being used -->
    <!--
    <xsl:variable name="lbi:metadata_fields"
        select="('094', '100', '110', '245', '246', '264', '260', '264', '300', '490', '500', '520', '545', '600', '630', '650', '651', '655', '700', '710', '773', '856')" />
    -->
    <!--
    <xsl:variable name="lbi:punctuation" select="',:;|/\-'" />
    -->
    <!-- Trim whitespace from start and end of a string; accepts one string parameter (string1) -->
    <!--
    <xsl:function name="lbi:trim">
        <xsl:param name="string1" />
        <xsl:value-of select="replace($string1, '^\s+|\s+$', '')" />
    </xsl:function>
    -->
    <xsl:function name="lbi:normalize">
        <!--
            Remove left-to-right mark and right-to-left mark non-printing characters (Unicode: U+200E, U+200F).
            Normalize-space (collapse and trim whitespace).
            Normalize-unicode (removes subtle differences in character representation).
                For example, u with an umlaut can be represented in the following two ways:
                (1) LATIN SMALL LETTER U WITH DIAERESIS: U+00fc
                (2) LATIN SMALL LETTER U [and] COMBINING DIAERESIS: U+0075 [and] U+0308
                These would be normalized as the first version.
        -->
        <xsl:param name="string1" />
        <xsl:value-of
            select="normalize-unicode(normalize-space(
            replace($string1, '[&#x200E;-&#x200F;]', '')
            ), 'NFC')"
         />
    </xsl:function>
    <xsl:template match="/">
        <xsl:result-document href="{$save_dir}add.xml" method="xml">
            <add>
                <!--
                    Only add records:
                        that do not have status=deleted,
                        that contain "griffinger_art" in the 583b,
                        and that contain "dps_pid" in the 856u (for Rosetta).
                -->
                <xsl:apply-templates
                    select="repository/record[
                        not(header[@status='deleted'])
                        and metadata/*:record/*:datafield[@tag = ('583')][*:subfield[@code='b'][contains(lower-case(.), 'griffinger_art')]]
                        and metadata/*:record/*:datafield[@tag = ('856')][contains(*:subfield[@code = 'u'], 'dps_pid')]
                    ]"
                 />
            </add>
        </xsl:result-document>
        <xsl:result-document href="{$save_dir}delete.xml" method="xml">
            <delete>
                <xsl:apply-templates select="repository/record[header[@status='deleted']]" />
            </delete>
        </xsl:result-document>
    </xsl:template>
    <!-- This template is not working on webfaction server, so lbi:normalize as also been used individually throughout this file. -->
    <!--
    <xsl:template match="text()">
        <xsl:value-of select="lbi:normalize(.)" />
    </xsl:template>
    -->
    <!-- Records to delete -->
    <xsl:template match="record[header[@status='deleted']]">
        <id>
            <!--
            <xsl:value-of select="header/identifier/substring-after(substring-after(lbi:normalize(.), ':'), ':')" />
            -->
            <xsl:value-of select="header/identifier/replace(substring-after(lbi:normalize(.), 'CJH01-'), '^0+', '')" />
        </id>
    </xsl:template>
    <!-- Records to add -->
    <xsl:template match="record">
        <doc>
            <xsl:apply-templates select="header/identifier" />
            <xsl:apply-templates select="metadata/*:record/*:datafield" />
            <!--
            <xsl:apply-templates select="metadata/*:record/*:controlfield" />
            -->
            <!--
            <xsl:apply-templates select="metadata/*:record/*:controlfield|metadata/*:record/*:datafield" />
            -->
        </doc>
    </xsl:template>
    <xsl:template match="identifier">
        <!--
        <field name="oai_identifier">
            <xsl:value-of select="lbi:trim(.)" />
        </field>
        -->
        <field name="record_id">
            <!-- Get ID from this string -->
            <xsl:value-of select="replace(substring-after(lbi:normalize(.), 'CJH01-'), '^0+', '')" />
        </field>
    </xsl:template>
    <!--
    <xsl:template match="*:controlfield">
        <field name="{lbi:trim(@tag)}">
            <xsl:value-of select="." />
        </field>
    </xsl:template>
    -->
    <!--
    <xsl:template match="*:datafield[@tag='650']">
        <xsl:value-of select="*:subfield" />
        <xsl:if test="position() != last()">
            <xsl:text>; </xsl:text>
        </xsl:if>
    </xsl:template>
    -->
    <!-- Catch-all template for datafield elements not specified in other templates. -->
    <xsl:template match="*:datafield">
        <xsl:variable name="tag" select="@tag" />
        <xsl:if test="$lbi:metadata_fields/metadata_field[@key=$tag]">
            <field name="{$lbi:metadata_fields/metadata_field[@key=$tag]}">
                <xsl:value-of select="lbi:normalize(.)" />
            </field>
        </xsl:if>
    </xsl:template>
    <!-- Do nothing -->
    <!--
    <xsl:template match="*:controlfield" />
    -->
    <!-- Get first date and second date, and make sure they are a number -->
    <!--
    <xsl:template match="*:controlfield[@tag='008'][1]">
        <xsl:if test="not(string(number(substring(., 8, 4))) = 'NaN')">
            <field name="date1_sort">
                <xsl:value-of select="substring(., 8, 4)" />
            </field>
        </xsl:if>

        <xsl:if test="not(string(number(substring(., 12, 4))) = 'NaN')">
            <field name="date2_sort">
                <xsl:value-of select="substring(., 12, 4)" />
            </field>
        </xsl:if>
    </xsl:template>
    -->
    <xsl:template match="*:datafield[@tag = ('100', '110')][1]">
        <field name="artist_sort">
            <xsl:if test="*:subfield[@code = 'a']">
                <xsl:value-of select="replace(lbi:normalize(*:subfield[@code = 'a'][1]), '[,:;]$', '')" />
            </xsl:if>
        </field>
        <xsl:call-template name="artist" />
    </xsl:template>
    <xsl:template match="*:datafield[@tag = ('100', '110')][position() > 1]">
        <xsl:call-template name="artist" />
    </xsl:template>
    <xsl:template name="artist">
        <xsl:variable name="tag" select="@tag" />
        <xsl:if test="$lbi:metadata_fields/metadata_field[@key=$tag]">
            <field name="{$lbi:metadata_fields/metadata_field[@key=$tag]}">
                <!--
                <xsl:value-of select="replace(*:subfield[@code!='2'], '^(.*)[\.:,]$', '$1')" separator=", " />
                -->
                <xsl:for-each select="*:subfield">
                    <xsl:choose>
                        <!-- If subfield a contains "unknown artist", ensure that "artist" is capitalized, and remove trailing period. -->
                        <xsl:when test="@code = 'a' and contains(lower-case(.), 'unknown')">
                            <xsl:value-of
                                select="
                                replace(
                                replace(lbi:normalize(.), 'artist', 'Artist'), '\.$', ''
                                )
                                "
                             />
                        </xsl:when>
                        <!-- For this subfield(s), remove trailing ".,:;" (includes period). -->
                        <xsl:when test="@code = 'd' or @code = 'e' or @code = 'j'">
                            <xsl:value-of select="replace(lbi:normalize(.), '[.,:;]$', '')" />
                        </xsl:when>
                        <!-- With all other subfields, remove trailing ",:;" (excludes period). -->
                        <xsl:otherwise>
                            <xsl:value-of select="replace(lbi:normalize(.), '[,:;]$', '')" />
                        </xsl:otherwise>
                    </xsl:choose>
                    <!-- If not the last subfield, add ", " -->
                    <xsl:if test="position()!= last()">
                        <xsl:text>, </xsl:text>
                    </xsl:if>
                </xsl:for-each>
            </field>
            <field name="{$lbi:metadata_fields/metadata_field[@key=$tag]}_brief">
                <xsl:for-each
                    select="*:subfield[(@code = 'a' or @code = 'b' or @code = 'c' or @code = 'd' or @code = 'q')]">
                    <xsl:choose>
                        <!-- If subfield a contains "unknown artist", ensure that "artist" is capitalized, and remove trailing period. -->
                        <xsl:when test="@code = 'a' and contains(lower-case(.), 'unknown')">
                            <xsl:value-of
                                select="
                                replace(
                                replace(lbi:normalize(.), 'artist', 'Artist'), '\.$', ''
                                )
                                "
                             />
                        </xsl:when>
                        <xsl:when test="@code = 'a'">
                            <xsl:value-of select="replace(lbi:normalize(.), '[,:;]$', '')" />
                        </xsl:when>
                        <xsl:when test="$tag = '100' and @code = 'c'">
                            <xsl:value-of select="replace(lbi:normalize(.), '[,:;]$', '')" />
                        </xsl:when>
                        <!-- For this subfield(s), remove trailing ".,:;" (includes period). -->
                        <xsl:when test="$tag = '100' and @code = 'd'">
                            <xsl:value-of select="replace(lbi:normalize(.), '[.,:;]$', '')" />
                        </xsl:when>
                        <xsl:when test="$tag = '100' and @code = 'q'">
                            <xsl:value-of select="replace(lbi:normalize(.), '[,:;]$', '')" />
                        </xsl:when>
                        <xsl:when test="$tag = '110' and @code = 'b'">
                            <xsl:value-of select="replace(lbi:normalize(.), '[,:;]$', '')" />
                        </xsl:when>
                    </xsl:choose>
                    <!-- If not the last subfield, add ", " -->
                    <xsl:if test="position()!= last()">
                        <xsl:text>, </xsl:text>
                    </xsl:if>
                </xsl:for-each>
            </field>
        </xsl:if>
    </xsl:template>
    <xsl:template match="*:datafield[@tag='245'][1]">
        <!-- Create field for sorting: title_sort -->
        <xsl:variable name="tag" select="@tag" />
        <xsl:if test="$lbi:metadata_fields/metadata_field[@key=$tag]">
            <field name="{$lbi:metadata_fields/metadata_field[@key=$tag]}_sort">
                <!--
                    <xsl:value-of select="replace(*:subfield[@code!='2'], '^(.*)[\.:,]$', '$1')" separator=", " />
                -->
                <xsl:for-each select="*:subfield">
                    <xsl:choose>
                        <xsl:when test="position()!= last()">
                            <xsl:value-of select="lbi:normalize(.)" />
                            <!-- If the subfield does not end with a specific punctuation mark, then add a comma. -->
                            <xsl:if test="not(contains(',:;|/\-', substring(., string-length(.))))">
                                <xsl:text>,</xsl:text>
                            </xsl:if>
                            <!-- Add a space. -->
                            <xsl:text> </xsl:text>
                        </xsl:when>
                        <xsl:otherwise>
                            <!-- In the last subfield, remove the trailing period. -->
                            <xsl:value-of select="replace(lbi:normalize(.), '\.$', '')" />
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:for-each>
            </field>
        </xsl:if>
        <xsl:call-template name="title" />
    </xsl:template>
    <xsl:template match="*:datafield[@tag='245'][position() > 1]">
        <xsl:call-template name="title" />
    </xsl:template>
    <xsl:template name="title">
        <xsl:variable name="tag" select="@tag" />
        <xsl:if test="$lbi:metadata_fields/metadata_field[@key=$tag]">
            <field name="{$lbi:metadata_fields/metadata_field[@key=$tag]}">
                <!--
                    <xsl:value-of select="replace(*:subfield[@code!='2'], '^(.*)[\.:,]$', '$1')" separator=", " />
                -->
                <xsl:for-each select="*:subfield">
                    <xsl:choose>
                        <xsl:when test="position()!= last()">
                            <xsl:value-of select="lbi:normalize(.)" />
                            <!-- If the subfield does not end with a specific punctuation mark, then add a comma. -->
                            <xsl:if test="not(contains(',:;|/\-', substring(., string-length(.))))">
                                <xsl:text>,</xsl:text>
                            </xsl:if>
                            <!-- Add a space. -->
                            <xsl:text> </xsl:text>
                        </xsl:when>
                        <xsl:otherwise>
                            <!-- In the last subfield, remove the trailing period. -->
                            <xsl:value-of select="replace(lbi:normalize(.), '\.$', '')" />
                        </xsl:otherwise>
                    </xsl:choose>
                    <!-- If this is not the last subfield, and if the subfield does not end with a specific punctuation mark, then add a comma. -->
                    <!--
                        <xsl:if test="position()!= last() and not(contains($lbi:punctuation, substring(., string-length(.))))">
                        <xsl:text>,</xsl:text>
                        </xsl:if>
                    -->
                    <!-- If this is not the last subfield, add a space. -->
                    <!--
                        <xsl:if test="position()!= last()">
                        <xsl:text> </xsl:text>
                        </xsl:if>
                    -->
                </xsl:for-each>
            </field>
        </xsl:if>
    </xsl:template>
    <xsl:template match="*:datafield[@tag = ('246', '300')]">
        <xsl:variable name="tag" select="@tag" />
        <xsl:if test="$lbi:metadata_fields/metadata_field[@key=$tag]">
            <field name="{$lbi:metadata_fields/metadata_field[@key=$tag]}">
                <!--
                <xsl:value-of select="replace(*:subfield[@code!='2'], '^(.*)[\.:,]$', '$1')" separator=", " />
                -->
                <xsl:for-each select="*:subfield">
                    <xsl:choose>
                        <xsl:when test="position()!= last()">
                            <xsl:value-of select="lbi:normalize(.)" />
                            <!-- If the subfield does not end with a specific punctuation mark, then add a comma. -->
                            <xsl:if test="not(contains(',:;|/\-', substring(., string-length(.))))">
                                <xsl:text>,</xsl:text>
                            </xsl:if>
                            <!-- Add a space. -->
                            <xsl:text> </xsl:text>
                        </xsl:when>
                        <xsl:otherwise>
                            <!-- In the last subfield, remove the trailing period. -->
                            <xsl:value-of select="replace(lbi:normalize(.), '\.$', '')" />
                        </xsl:otherwise>
                    </xsl:choose>
                    <!-- If this is not the last subfield, and if the subfield does not end with a specific punctuation mark, then add a comma. -->
                    <!--
                        <xsl:if test="position()!= last() and not(contains($lbi:punctuation, substring(., string-length(.))))">
                        <xsl:text>,</xsl:text>
                        </xsl:if>
                    -->
                    <!-- If this is not the last subfield, add a space. -->
                    <!--
                        <xsl:if test="position()!= last()">
                        <xsl:text> </xsl:text>
                        </xsl:if>
                    -->
                </xsl:for-each>
            </field>
        </xsl:if>
    </xsl:template>
    <xsl:template match="*:datafield[@tag = ('260', '264')][1]">
        <xsl:if test="*:subfield[@code = 'c']">
            <xsl:if test="matches(*:subfield[@code = 'c'][0], '^.*?(\d{4}).*$')">
                <field name="date_sort">
                    <xsl:value-of select="replace(*:subfield[@code = 'c'], '^.*?(\d{4}).*$', '$1')" />
                </field>
            </xsl:if>
            <!--
            /repository/record/metadata/*:record/*:datafield[@tag='260']/*:subfield[@code = 'c'][text()='20th century.']
            replace(lbi:normalize(.), '\.$', '')
            lower-case(.)
            -->
            <xsl:choose>
                <xsl:when
                    test="*:subfield[@code = 'c'][replace(lbi:normalize(lower-case(text())), '\.$', '')='15th century']">
                    <field name="date_sort">
                        <xsl:text>1400</xsl:text>
                    </field>
                </xsl:when>
                <xsl:when
                    test="*:subfield[@code = 'c'][replace(lbi:normalize(lower-case(text())), '\.$', '')='16th century']">
                    <field name="date_sort">
                        <xsl:text>1500</xsl:text>
                    </field>
                </xsl:when>
                <xsl:when
                    test="*:subfield[@code = 'c'][replace(lbi:normalize(lower-case(text())), '\.$', '')='17th century']">
                    <field name="date_sort">
                        <xsl:text>1600</xsl:text>
                    </field>
                </xsl:when>
                <xsl:when
                    test="*:subfield[@code = 'c'][replace(lbi:normalize(lower-case(text())), '\.$', '')='18th century']">
                    <field name="date_sort">
                        <xsl:text>1700</xsl:text>
                    </field>
                </xsl:when>
                <xsl:when
                    test="*:subfield[@code = 'c'][replace(lbi:normalize(lower-case(text())), '\.$', '')='19th century']">
                    <field name="date_sort">
                        <xsl:text>1800</xsl:text>
                    </field>
                </xsl:when>
                <xsl:when
                    test="*:subfield[@code = 'c'][replace(lbi:normalize(lower-case(text())), '\.$', '')='20th century']">
                    <field name="date_sort">
                        <xsl:text>1900</xsl:text>
                    </field>
                </xsl:when>
            </xsl:choose>
        </xsl:if>
        <xsl:call-template name="pub" />
    </xsl:template>
    <xsl:template match="*:datafield[@tag = ('260', '264')][position() > 1]">
        <xsl:call-template name="pub" />
    </xsl:template>
    <!-- 260 and 264 are combined together, then split according to subfield. -->
    <xsl:template name="pub">
        <xsl:variable name="tag" select="@tag" />
        <xsl:if test="$lbi:metadata_fields/metadata_field[@key=$tag]">
            <xsl:for-each select="*:subfield">
                <xsl:if test="@code = 'a'">
                    <field name="{$lbi:metadata_fields/metadata_field[@key=$tag]}_place">
                        <!-- Remove trailing colon. -->
                        <xsl:value-of select="replace(lbi:normalize(.), '[,:]$', '')" />
                    </field>
                </xsl:if>
                <xsl:if test="@code = 'b'">
                    <field name="publisher_name">
                        <!-- Remove trailing comma. -->
                        <xsl:value-of select="replace(lbi:normalize(.), ',$', '')" />
                    </field>
                </xsl:if>
                <xsl:if test="@code = 'c'">
                    <field name="{$lbi:metadata_fields/metadata_field[@key=$tag]}_date">
                        <!-- Remove the trailing period. -->
                        <xsl:value-of select="replace(lbi:normalize(.), '\.$', '')" />
                    </field>
                </xsl:if>
            </xsl:for-each>
        </xsl:if>
    </xsl:template>
    <xsl:template match="*:datafield[@tag = ('520', '545')]">
        <xsl:variable name="tag" select="@tag" />
        <xsl:if test="$lbi:metadata_fields/metadata_field[@key=$tag]">
            <field name="{$lbi:metadata_fields/metadata_field[@key=$tag]}">
                <xsl:for-each select="*:subfield">
                    <xsl:value-of select="lbi:normalize(.)" />
                    <xsl:if test="position()!= last()">
                        <xsl:text> </xsl:text>
                    </xsl:if>
                </xsl:for-each>
            </field>
        </xsl:if>
    </xsl:template>
    <!-- Skip 583 fields that do not contain griffinger_art -->
    <xsl:template
        match="*:datafield[@tag = ('583')][not(*:subfield[@code='b'][contains(lower-case(.), 'griffinger_art')])]" />
    <!-- Skip 583 fields that contain griffinger_art after the first one -->
    <xsl:template
        match="*:datafield[@tag = ('583')][*:subfield[@code='b'][contains(lower-case(.), 'griffinger_art')]][position() > 1]" />
    <!-- Use the first 583 field that contains griffinger_art -->
    <xsl:template
        match="*:datafield[@tag = ('583')][*:subfield[@code='b'][contains(lower-case(.), 'griffinger_art')]][position() = 1]">
        <xsl:variable name="tag" select="@tag" />
        <xsl:if test="$lbi:metadata_fields/metadata_field[@key=$tag]">
            <field name="{$lbi:metadata_fields/metadata_field[@key=$tag]}">
                <xsl:value-of select="*:subfield" />
            </field>
        </xsl:if>
    </xsl:template>
    <xsl:template match="*:datafield[@tag = ('600')]">
        <xsl:variable name="tag" select="@tag" />
        <xsl:if test="$lbi:metadata_fields/metadata_field[@key=$tag]">
            <field name="{$lbi:metadata_fields/metadata_field[@key=$tag]}">
                <!--
                <xsl:value-of select="replace(*:subfield[@code!='2'], '^(.*)[\.:,]$', '$1')" separator=", " />
                -->
                <xsl:for-each select="*:subfield[not(@code = '2')]">
                    <xsl:choose>
                        <!-- For this subfield(s), remove trailing ".,:;" (includes period). -->
                        <xsl:when test="@code = 'd' or @code = 'e' or @code = 'j'">
                            <xsl:value-of select="replace(lbi:normalize(.), '[.,:;]$', '')" />
                        </xsl:when>
                        <!-- With all other subfields, remove trailing ",:;" (excludes period). -->
                        <xsl:otherwise>
                            <xsl:value-of select="replace(lbi:normalize(.), '[,:;]$', '')" />
                        </xsl:otherwise>
                    </xsl:choose>
                    <!-- If not the last subfield, add ", " -->
                    <xsl:if test="position()!= last()">
                        <xsl:text>, </xsl:text>
                    </xsl:if>
                </xsl:for-each>
            </field>
            <field name="{$lbi:metadata_fields/metadata_field[@key=$tag]}_brief">
                <xsl:for-each select="*:subfield[(@code = 'a' or @code = 'c' or @code = 'd' or @code = 'q')]">
                    <xsl:choose>
                        <!-- For this subfield(s), remove trailing ".,:;" (includes period). -->
                        <xsl:when test="@code = 'd'">
                            <xsl:value-of select="replace(lbi:normalize(.), '[.,:;]$', '')" />
                        </xsl:when>
                        <!-- Remove trailing ",:;" (excludes period). -->
                        <xsl:otherwise>
                            <xsl:value-of select="replace(lbi:normalize(.), '[,:;]$', '')" />
                        </xsl:otherwise>
                    </xsl:choose>
                    <!-- If not the last subfield, add ", " -->
                    <xsl:if test="position()!= last()">
                        <xsl:text>, </xsl:text>
                    </xsl:if>
                </xsl:for-each>
            </field>
        </xsl:if>
    </xsl:template>
    <xsl:template match="*:datafield[@tag = ('630', '650')]">
        <xsl:variable name="tag" select="@tag" />
        <xsl:if test="$lbi:metadata_fields/metadata_field[@key=$tag]">
            <field name="{$lbi:metadata_fields/metadata_field[@key=$tag]}">
                <!--
                <xsl:value-of select="replace(*:subfield[@code!='2'], '^(.*)[\.:,]$', '$1')" separator=", " />
                -->
                <xsl:for-each select="*:subfield[not(@code = '2')]">
                    <xsl:choose>
                        <!-- For this subfield(s), remove trailing ".,:;" (includes period). -->
                        <xsl:when
                            test="@code = 'a' or @code = 'd' or @code = 'e' or @code = 'j' or @code = 'v' or @code = 'x' or @code = 'y' or @code = 'z'">
                            <xsl:value-of select="replace(lbi:normalize(.), '[.,:;]$', '')" />
                        </xsl:when>
                        <!-- With all other subfields, remove trailing ",:;" (excludes period). -->
                        <xsl:otherwise>
                            <xsl:value-of select="replace(lbi:normalize(.), '[,:;]$', '')" />
                        </xsl:otherwise>
                    </xsl:choose>
                    <!-- If not the last subfield, add ", " -->
                    <xsl:if test="position()!= last()">
                        <xsl:text>, </xsl:text>
                    </xsl:if>
                </xsl:for-each>
            </field>
        </xsl:if>
    </xsl:template>
    <xsl:template match="*:datafield[@tag = ('651')]">
        <xsl:variable name="tag" select="@tag" />
        <xsl:if test="$lbi:metadata_fields/metadata_field[@key=$tag]">
            <field name="{$lbi:metadata_fields/metadata_field[@key=$tag]}">
                <!--
                    <xsl:value-of select="replace(*:subfield[@code!='2'], '^(.*)[\.:,]$', '$1')" separator=", " />
                -->
                <xsl:for-each select="*:subfield[not(@code = '2')]">
                    <xsl:choose>
                        <!-- For this subfield(s), remove trailing ".,:;" (includes period). -->
                        <xsl:when
                            test="@code = 'a' or @code = 'd' or @code = 'e' or @code = 'j' or @code = 'v' or @code = 'x' or @code = 'y' or @code = 'z'">
                            <xsl:value-of select="replace(lbi:normalize(.), '[.,:;]$', '')" />
                        </xsl:when>
                        <!-- With all other subfields, remove trailing ",:;" (excludes period). -->
                        <xsl:otherwise>
                            <xsl:value-of select="replace(lbi:normalize(.), '[,:;]$', '')" />
                        </xsl:otherwise>
                    </xsl:choose>
                    <!-- If not the last subfield, add ", " -->
                    <xsl:if test="position()!= last()">
                        <xsl:text>, </xsl:text>
                    </xsl:if>
                </xsl:for-each>
            </field>
            <field name="{$lbi:metadata_fields/metadata_field[@key=$tag]}_brief">
                <xsl:for-each select="*:subfield[(@code = 'a')]">
                    <!-- For this subfield(s), remove trailing ".,:;" (includes period). -->
                    <xsl:value-of select="replace(lbi:normalize(.), '[.,:;]$', '')" />
                </xsl:for-each>
            </field>
        </xsl:if>
    </xsl:template>
    <xsl:template
        match="*:datafield[@tag = ('655')][
        *:subfield[@code = ('v')] = 'Genre' 
        or not(*:subfield[@code = ('2')] = 'cjh')  
        ]">
        <xsl:variable name="tag" select="@tag" />
        <xsl:if test="$lbi:metadata_fields/metadata_field[@key=$tag]">
            <field name="genre">
                <!--
                    <xsl:value-of select="replace(*:subfield[@code!='2'], '^(.*)[\.:,]$', '$1')" separator=", " />
                -->
                <xsl:for-each select="*:subfield[not(@code = 'v')][not(@code = '2')]">
                    <xsl:choose>
                        <!-- For this subfield(s), remove trailing ".,:;" (includes period). -->
                        <xsl:when
                            test="@code = 'a' or @code = 'd' or @code = 'e' or @code = 'j' or @code = 'v' or @code = 'x' or @code = 'y' or @code = 'z'">
                            <xsl:value-of select="replace(lbi:normalize(.), '[.,:;]$', '')" />
                        </xsl:when>
                        <!-- With all other subfields, remove trailing ",:;" (excludes period). -->
                        <xsl:otherwise>
                            <xsl:value-of select="replace(lbi:normalize(.), '[,:;]$', '')" />
                        </xsl:otherwise>
                    </xsl:choose>
                    <!-- If not the last subfield, add ", " -->
                    <xsl:if test="position()!= last()">
                        <xsl:text>, </xsl:text>
                    </xsl:if>
                </xsl:for-each>
            </field>
        </xsl:if>
    </xsl:template>
    <xsl:template
        match="*:datafield[@tag = ('655')][
        *:subfield[@code = ('2')] = 'cjh'
        and not(*:subfield[@code = ('v')] = 'Genre')
        ]">
        <xsl:variable name="tag" select="@tag" />
        <xsl:if test="$lbi:metadata_fields/metadata_field[@key=$tag]">
            <field name="medium">
                <!--
                        <xsl:value-of select="replace(*:subfield[@code!='2'], '^(.*)[\.:,]$', '$1')" separator=", " />
                    -->
                <xsl:for-each select="*:subfield[not(@code = '2')]">
                    <xsl:choose>
                        <!-- For this subfield(s), remove trailing ".,:;" (includes period). -->
                        <xsl:when
                            test="@code = 'a' or @code = 'd' or @code = 'e' or @code = 'j' or @code = 'v' or @code = 'x' or @code = 'y' or @code = 'z'">
                            <xsl:value-of select="replace(lbi:normalize(.), '[.,:;]$', '')" />
                        </xsl:when>
                        <!-- With all other subfields, remove trailing ",:;" (excludes period). -->
                        <xsl:otherwise>
                            <xsl:value-of select="replace(lbi:normalize(.), '[,:;]$', '')" />
                        </xsl:otherwise>
                    </xsl:choose>
                    <!-- If not the last subfield, add ", " -->
                    <xsl:if test="position()!= last()">
                        <xsl:text>, </xsl:text>
                    </xsl:if>
                </xsl:for-each>
            </field>
        </xsl:if>
    </xsl:template>
    <xsl:template match="*:datafield[@tag = ('700')]">
        <xsl:variable name="tag" select="@tag" />
        <xsl:if test="$lbi:metadata_fields/metadata_field[@key=$tag]">
            <field name="{$lbi:metadata_fields/metadata_field[@key=$tag]}">
                <!--
                <xsl:value-of select="replace(*:subfield[@code!='2'], '^(.*)[\.:,]$', '$1')" separator=", " />
                -->
                <xsl:for-each select="*:subfield">
                    <xsl:choose>
                        <!-- For this subfield(s), remove trailing ".,:;" (includes period). -->
                        <xsl:when test="@code = 'd' or @code = 'e' or @code = 'j'">
                            <xsl:value-of select="replace(lbi:normalize(.), '[.,:;]$', '')" />
                        </xsl:when>
                        <!-- With all other subfields, remove trailing ",:;" (excludes period). -->
                        <xsl:otherwise>
                            <xsl:value-of select="replace(lbi:normalize(.), '[,:;]$', '')" />
                        </xsl:otherwise>
                    </xsl:choose>
                    <!-- If not the last subfield, add ", " -->
                    <xsl:if test="position()!= last()">
                        <xsl:text>, </xsl:text>
                    </xsl:if>
                </xsl:for-each>
            </field>
            <field name="{$lbi:metadata_fields/metadata_field[@key=$tag]}_brief">
                <xsl:for-each select="*:subfield[(@code = 'a' or @code = 'c' or @code = 'd' or @code = 'q')]">
                    <xsl:choose>
                        <!-- For this subfield(s), remove trailing ".,:;" (includes period). -->
                        <xsl:when test="@code = 'd'">
                            <xsl:value-of select="replace(lbi:normalize(.), '[.,:;]$', '')" />
                        </xsl:when>
                        <!-- Remove trailing ",:;" (excludes period). -->
                        <xsl:otherwise>
                            <xsl:value-of select="replace(lbi:normalize(.), '[,:;]$', '')" />
                        </xsl:otherwise>
                    </xsl:choose>
                    <!-- If not the last subfield, add ", " -->
                    <xsl:if test="position()!= last()">
                        <xsl:text>, </xsl:text>
                    </xsl:if>
                </xsl:for-each>
            </field>
        </xsl:if>
    </xsl:template>
    <xsl:template match="*:datafield[@tag = ('710')]">
        <xsl:variable name="tag" select="@tag" />
        <xsl:if test="$lbi:metadata_fields/metadata_field[@key=$tag]">
            <field name="{$lbi:metadata_fields/metadata_field[@key=$tag]}">
                <!--
                <xsl:value-of select="replace(*:subfield[@code!='2'], '^(.*)[\.:,]$', '$1')" separator=", " />
                -->
                <xsl:for-each select="*:subfield">
                    <xsl:choose>
                        <!-- For this subfield(s), remove trailing ".,:;" (includes period). -->
                        <xsl:when test="@code = 'd' or @code = 'e' or @code = 'j'">
                            <xsl:value-of select="replace(lbi:normalize(.), '[.,:;]$', '')" />
                        </xsl:when>
                        <!-- With all other subfields, remove trailing ",:;" (excludes period). -->
                        <xsl:otherwise>
                            <xsl:value-of select="replace(lbi:normalize(.), '[,:;]$', '')" />
                        </xsl:otherwise>
                    </xsl:choose>
                    <!-- If not the last subfield, add ", " -->
                    <xsl:if test="position()!= last()">
                        <xsl:text>, </xsl:text>
                    </xsl:if>
                </xsl:for-each>
            </field>
            <field name="{$lbi:metadata_fields/metadata_field[@key=$tag]}_brief">
                <xsl:for-each select="*:subfield[(@code = 'a' or @code = 'b')]">
                    <!-- Remove trailing ",:;" (excludes period). -->
                    <xsl:value-of select="replace(lbi:normalize(.), '[,:;]$', '')" />
                    <!-- If not the last subfield, add ", " -->
                    <xsl:if test="position()!= last()">
                        <xsl:text>, </xsl:text>
                    </xsl:if>
                </xsl:for-each>
            </field>
        </xsl:if>
    </xsl:template>
    <xsl:template match="*:datafield[@tag = ('856')][1]">
        <xsl:variable name="tag" select="@tag" />
        <xsl:if test="$lbi:metadata_fields/metadata_field[@key=$tag]">
            <field name="{$lbi:metadata_fields/metadata_field[@key=$tag]}">
                <xsl:value-of select="lbi:normalize(*:subfield[@code = 'u'])[1]" />
            </field>
        </xsl:if>
    </xsl:template>
    <xsl:template match="*:datafield[@tag='856'][position() > 1]" />
</xsl:stylesheet>
