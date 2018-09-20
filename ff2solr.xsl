<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xs="http://www.w3.org/2001/XMLSchema-instance"
                xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                xmlns:ff="http://www.kulturarv.dk/fundogfortidsminder/ff"
                xmlns:gml="http://www.opengis.net/gml"
                version="1.0" exclude-result-prefixes="xs xsl ff gml">
  <xsl:output version="1.0" encoding="UTF-8" indent="yes" method="xml" omit-xml-declaration="no"/>

  <!-- Ignore all un-matched -->
  <xsl:template match="text()"/>
  
  <xsl:template match="//metadata/ff:site">
    <add><doc>
      <xsl:for-each select=".">
        <xsl:apply-templates/>
      </xsl:for-each>
    </doc></add>
  </xsl:template>
  
  <!-- place name -->
  <xsl:template match="ff:placeNames">
    <xsl:for-each select="ff:placeName">
      <xsl:if test="position() = last()">
        <field name="place_name"><xsl:value-of select="ff:name"/></field>
      </xsl:if>
    </xsl:for-each>
  </xsl:template>
  
  <!-- gml coordinates -->
  <xsl:template match="ff:geodata">
    <xsl:for-each select="gml:Point">
      <field name="gml_region_s"><xsl:value-of select="@srsName"/></field>
      <field name="gml_dimensions_s"><xsl:value-of select="gml:pos"/></field>
    </xsl:for-each>
  </xsl:template>

  <!-- primary object -->
  <xsl:template match="ff:objects">
    <xsl:for-each select="ff:primaryObject">

      <xsl:for-each select="ff:text">
        <field name="object_text_t"><xsl:value-of select="."/></field>
      </xsl:for-each>

      <xsl:for-each select="ff:from_year">
        <field name="object_year_from_i"><xsl:value-of select="."/></field>
      </xsl:for-each>

      <xsl:for-each select="ff:to_year">
        <field name="object_year_to_i"><xsl:value-of select="."/></field>
      </xsl:for-each>

      <xsl:for-each select="ff:objectType">
        <xsl:for-each select="ff:term">
          <field name="object_type_s"><xsl:value-of select="."/></field>
      </xsl:for-each>
      </xsl:for-each>

    </xsl:for-each>
  </xsl:template>

  <!-- case number -->
  <xsl:template match="ff:events">
    <xsl:for-each select="ff:event">
      <xsl:for-each select="ff:caseNo">
        <field name="case"><xsl:value-of select="."/></field>
      </xsl:for-each>
    </xsl:for-each>
  </xsl:template>

</xsl:stylesheet>
