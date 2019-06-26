<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xs="http://www.w3.org/2001/XMLSchema-instance"
                xmlns:oai_dc="http://www.openarchives.org/OAI/2.0/oai_dc/"
                xmlns:dc="http://purl.org/dc/elements/1.1/"
                xmlns:xoai="http://www.lyncode.com/xoai"
                xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                xmlns:md="http://www.loc.gov/mods/v3"
                xmlns:georss="http://www.georss.org/georss"
                xmlns:geo="http://www.w3.org/2003/01/geo/wgs84_pos#"
                xsi:schemaLocation="http://www.lyncode.com/xoai http://www.lyncode.com/xsd/xoai.xsd"
                version="1.0" exclude-result-prefixes="xs xsl xoai dc oai_dc md geo georss">
  <xsl:output version="1.0" encoding="UTF-8" indent="yes" method="xml" omit-xml-declaration="no"/>
  <xsl:strip-space elements="*"/>
  
  <xsl:template match="/item">
    <add><doc>
      <xsl:text>&#10;</xsl:text>
      <xsl:for-each select="*">
        <xsl:apply-templates/>
      </xsl:for-each>
    </doc></add>
  </xsl:template>

  <xsl:template match="georss:*/"/>
  <xsl:template match="geo:*/"/>

  <!-- title -->
  <xsl:template match="title/">
    <field name="title"><xsl:value-of select="."/></field>
    <xsl:text>&#10;</xsl:text>
  </xsl:template>

  <!-- id (wrongly named as we do not use loar here) -->
  <xsl:template match="link/">
    <xsl:variable name="id" select="concat('pp_', translate(substring-after(., '://'),'/','_'))"/>
    <field name="id"><xsl:value-of select="$id"/></field>
    <xsl:text>&#10;</xsl:text>
    <field name="loar_id"><xsl:value-of select="$id"/></field>
    <xsl:text>&#10;</xsl:text>
  </xsl:template>

  <!-- Debug-helper. Not needed in production -->
  <xsl:template match="md:mods/md:name[ms:role/md:roleTerm/text()='creator']">
      *************** DEVEL(<xsl:value-of select ="name(.)"/>)
  </xsl:template>

  <!-- external PDF -->
  <xsl:template match="md:mods/md:identifier">
    <xsl:if test="./@displayLabel='pdf'">
      <field name="external_resource"><xsl:value-of select="."/></field>
      <xsl:text>&#10;</xsl:text>
    </xsl:if>
  </xsl:template>
  
  <!-- keywords -->
  <xsl:template match="md:mods/md:subject">
    <xsl:for-each select="md:topic">
      <xsl:call-template name="split">
        <xsl:with-param name="pText" select="."/>
        <xsl:with-param name="pItemElementName" select="'keyword'"/>
        <xsl:with-param name="pItemElementNamespace" select="''"/>
      </xsl:call-template>
    </xsl:for-each>
  </xsl:template>

  <!-- author -->
  <xsl:template match="md:mods/md:name">
    <xsl:if test="md:role/md:roleTerm/text()='creator'">
      <field name="author"><xsl:value-of select="md:namePart"/></field>
      <xsl:text>&#10;</xsl:text>
    </xsl:if>
  </xsl:template>

  <!-- ctime (creation time) -->
  <xsl:template match="md:mods/md:originInfo">
    <xsl:for-each select="md:dateCreated[position()=1]"> 
      <field name="ctime">
        <xsl:choose>
          <xsl:when test="string-length(.) = 20">
            <xsl:value-of select="."/>
          </xsl:when>
          <xsl:when test="string-length(.) = 4">
            <xsl:value-of select="."/><xsl:text>-01-01T00:00:00Z</xsl:text>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="."/><xsl:text>T00:00:00Z</xsl:text>
          </xsl:otherwise>
        </xsl:choose>
      </field>
      <xsl:text>&#10;</xsl:text>
    </xsl:for-each>
  </xsl:template>

  <xsl:template match="*">
<!--    unhandled(<xsl:value-of select ="name(.)"/>)-->
  </xsl:template>

  <!-- https://stackoverflow.com/questions/8500652/comma-separated-string-parsing-xslt-to-for-each-node -->
  <xsl:template match="_nothing_" name="split">
    <xsl:param name="pText" select="."/>
    <xsl:param name="pItemElementName" select="'tns:AvailableDate'"/>
    <xsl:param name="pItemElementNamespace" select="'tns:tns'"/>

    <xsl:if test="string-length($pText) > 0">
      <xsl:variable name="vNextItem" select=
                    "substring-before(concat($pText, ', '), ', ')"/>

      <field name="{$pItemElementName}"><xsl:value-of select="$vNextItem"/></field>
      <xsl:text>&#10;</xsl:text>

      <xsl:call-template name="split">
        <xsl:with-param name="pText" select=
                        "substring-after($pText, ', ')"/>
        <xsl:with-param name="pItemElementName" select="$pItemElementName"/>
        <xsl:with-param name="pItemElementNamespace" select="$pItemElementNamespace"/>
      </xsl:call-template>
    </xsl:if>
  </xsl:template>
    
</xsl:stylesheet>

  
