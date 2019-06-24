<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xs="http://www.w3.org/2001/XMLSchema-instance"
                xmlns:oai_dc="http://www.openarchives.org/OAI/2.0/oai_dc/"
                xmlns:dc="http://purl.org/dc/elements/1.1/"
                xmlns:xoai="http://www.lyncode.com/xoai"
                xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                xsi:schemaLocation="http://www.lyncode.com/xoai http://www.lyncode.com/xsd/xoai.xsd"
                version="1.0" exclude-result-prefixes="xs xsl xoai dc oai_dc">
  <xsl:output version="1.0" encoding="UTF-8" indent="yes" method="xml" omit-xml-declaration="no"/>
  
  <xsl:template match="/">
    <add><doc>
      <xsl:for-each select="./*">
        <xsl:apply-templates/>
      </xsl:for-each>
    </doc></add>
  </xsl:template>
  
  <xsl:template match="record/header/identifier">
    <!-- The ID is likely to be extended -->
    <field name="id">
      <xsl:value-of select="."/>
    </field>
    <xsl:text>
        </xsl:text>
    <field name="loar_id">
      <xsl:value-of select="."/>
    </field>
  </xsl:template>

  <!-- datestamp and setSpec does not have a namespace here so the XSLT
       outputs their values raw, if not matched -->
  <xsl:template match="record/header/datestamp"/>
  <xsl:template match="record/header/setSpec"/>

  <xsl:template match="record/metadata">

    <xsl:for-each select="oai_dc:dc">
    <!-- TODO: Internal reference? -->

      <!-- authors -->
      <xsl:for-each select="xoai:element[@name='contributor']">
        <xsl:for-each select="xoai:element[@name='author']">
          <xsl:for-each select="xoai:element">
            <xsl:for-each select="xoai:field[@name='value']">
              <field name="author">
                <xsl:value-of select="."/>
              </field>
            </xsl:for-each>
          </xsl:for-each>
        </xsl:for-each>
      </xsl:for-each>
      
      <!-- date -->
      <xsl:if test="dc:date">
        <field name="ctime">
          <xsl:choose>
            <xsl:when test="string-length(dc:date) = 20">
              <xsl:value-of select="dc:date"/>
            </xsl:when>
            <xsl:when test="string-length(dc:date) = 4">
              <xsl:value-of select="dc:date"/><xsl:text>-01-01T00:00:00Z</xsl:text>
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="dc:date"/><xsl:text>T00:00:00Z</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </field>
        <xsl:text>
      </xsl:text>
      </xsl:if>        
      
      <!-- title -->
      <xsl:for-each select="dc:title[position()&lt;=1]">
        <field name="title">
          <xsl:value-of select="."/>
        </field>
        <xsl:text>
      </xsl:text>
      </xsl:for-each>

      <!-- LOAR URI -->
      <!--
      <dc:identifier>kirke_ringkoebing_flynder-kirke</dc:identifier>
      <dc:identifier>https://dspace-stage.statsbiblioteket.dk/handle/1902/8975</dc:identifier>
      -->
      <xsl:for-each select="dc:identifier">
        <xsl:choose>
          <xsl:when test="starts-with(., 'http')">
            <field name="loar_uri">
              <xsl:value-of select="."/>
            </field>
          </xsl:when>
          <xsl:otherwise>
            <field name="case">
              <xsl:value-of select="."/>
            </field>
          </xsl:otherwise>
        </xsl:choose>
        <xsl:text>
      </xsl:text>
      </xsl:for-each>

      <!-- external PDF -->
      <xsl:for-each select="dc:relation">
        <field name="external_resource">
          <xsl:value-of select="."/>
        </field>
        <xsl:text>
      </xsl:text>
      </xsl:for-each>

      <!-- location -->
      <xsl:for-each select="dc:coverage">
        <xsl:variable name="cov" select="'0123456789.,'"/>
        <xsl:choose>
          <xsl:when test="string-length(translate(., $cov, '')) = 0">
            <field name="place_coordinates">
              <xsl:value-of select="."/>
            </field>
          </xsl:when>
          <xsl:otherwise>
            <field name="place_name">
              <xsl:value-of select="."/>
            </field>
          </xsl:otherwise>
        </xsl:choose>
        <xsl:text>
      </xsl:text>
      </xsl:for-each>

    </xsl:for-each>

    <!-- local PDF -->
    <xsl:for-each select="xoai:element[@name='bundles']">
      <xsl:for-each select="xoai:element[@name='bundle']">
        <xsl:if test="xoai:field[@name='name'] = 'ORIGINAL'">
          <xsl:for-each select="xoai:element[@name='bitstreams']">
            <xsl:for-each select="xoai:element[@name='bitstream']">
              <xsl:for-each select="xoai:field[@name='url']">
                <field name="loar_resource">
                  <xsl:value-of select="."/>
                </field>
              </xsl:for-each>
            </xsl:for-each>
          </xsl:for-each>
        </xsl:if>
      </xsl:for-each>
    </xsl:for-each>
    
  </xsl:template>

</xsl:stylesheet>

  
