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
  
  <xsl:template match="ff:parishNo">
    <xsl:for-each select="ff:term">
      <xsl:if test="position() = last()">
        <field name="ff_parish_ss"><xsl:value-of select="."/></field>
      </xsl:if>
    </xsl:for-each>
  </xsl:template>

  <!-- admin area -->
  <xsl:template match="ff:adminArea">
    <xsl:for-each select="ff:municipality">
      <xsl:for-each select="ff:term">
        <field name="ff_adminarea_municipality_s"><xsl:value-of select="."/></field>
      </xsl:for-each>
    </xsl:for-each>

    <xsl:for-each select="ff:museum">
      <xsl:for-each select="ff:term">
        <field name="ff_adminarea_museum_s"><xsl:value-of select="."/></field>
      </xsl:for-each>
    </xsl:for-each>
    
    <xsl:for-each select="ff:supervision">
      <xsl:for-each select="ff:term">
        <field name="ff_adminarea_supervision_s"><xsl:value-of select="."/></field>
      </xsl:for-each>
    </xsl:for-each>
    
  </xsl:template>
  
  <!-- place name -->
  <xsl:template match="ff:placeNames">

    <xsl:for-each select="ff:placeName">
      <xsl:if test="position() = last()">
        <field name="place_name"><xsl:value-of select="ff:name"/></field>

        <xsl:for-each select="ff:placeNameType">
          <field name="ff_place_name_type_s"><xsl:value-of select="ff:term"/></field>
        </xsl:for-each>
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
        <field name="ff_primaryobject_text_t"><xsl:value-of select="."/></field>
      </xsl:for-each>

      <xsl:for-each select="ff:date">
        <xsl:for-each select="ff:fromYear">
          <field name="ff_primaryobject_year_from_i"><xsl:value-of select="."/></field>
        </xsl:for-each>
        <xsl:for-each select="ff:toYear">
          <field name="ff_primaryobject_year_to_i"><xsl:value-of select="."/></field>
        </xsl:for-each>
        <xsl:for-each select="ff:mainPeriod">
          <field name="ff_primaryobject_mainperiod_s"><xsl:value-of select="."/></field>
        </xsl:for-each>
        <xsl:for-each select="ff:period">
          <xsl:for-each select="ff:term">
            <field name="ff_primaryobject_period_term_s"><xsl:value-of select="."/></field>
          </xsl:for-each>
          <xsl:for-each select="ff:publicTerm">
            <field name="ff_primaryobject_period_publicterm_s"><xsl:value-of select="."/></field>
          </xsl:for-each>
        </xsl:for-each>
      </xsl:for-each>

      <xsl:for-each select="ff:objectType">
        <xsl:for-each select="ff:term">
          <field name="ff_primaryobject_type_term_s"><xsl:value-of select="."/></field>
        </xsl:for-each>
        <xsl:for-each select="ff:objectClassTerm">
          <field name="ff_primaryobject_type_class_term_s"><xsl:value-of select="."/></field>
        </xsl:for-each>
        <xsl:for-each select="ff:objectClassExplanation">
          <field name="ff_primaryobject_type_class_explanation_s"><xsl:value-of select="."/></field>
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

      <xsl:for-each select="ff:institution">
        <xsl:for-each select="ff:term">
          <field name="ff_events_institution_ss"><xsl:value-of select="."/></field>
        </xsl:for-each>
      </xsl:for-each>

      <xsl:for-each select="ff:texts">
        <xsl:for-each select="ff:text">
          <xsl:for-each select="ff:freeText">
            <field name="ff_events_text_ts"><xsl:value-of select="."/></field>
          </xsl:for-each>
        </xsl:for-each>
      </xsl:for-each>
    </xsl:for-each>
   
  </xsl:template>

</xsl:stylesheet>
