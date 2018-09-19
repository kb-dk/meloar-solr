<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xs="http://www.w3.org/2001/XMLSchema-instance"
                xmlns:xoai="http://www.lyncode.com/xoai"
                xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                xsi:schemaLocation="http://www.lyncode.com/xoai http://www.lyncode.com/xsd/xoai.xsd"
                version="1.0" exclude-result-prefixes="xs xsl xoai">
  <xsl:output version="1.0" encoding="UTF-8" indent="yes" method="xml" omit-xml-declaration="no"/>
  
  <xsl:template match="/">
    <doc>
      <xsl:for-each select="./*">
        <xsl:apply-templates/>
      </xsl:for-each>
    </doc>
  </xsl:template>
  
  <xsl:template match="record/header/identifier">
    <!-- The ID is likely to be extended -->
    <field name="id">
      <xsl:value-of select="."/>
    </field>
    <field name="loar_id">
      <xsl:value-of select="."/>
    </field>
  </xsl:template>

  <!-- datestamp and setSpec does not have a namespace here so the XSLT
       outputs their values raw, if not matched -->
  <xsl:template match="record/header/datestamp"/>
  <xsl:template match="record/header/setSpec"/>

  <xsl:template match="record/metadata/xoai:metadata">

    <xsl:for-each select="xoai:element[@name='dc']">
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

      <!-- keywords -->
      <xsl:for-each select="xoai:element[@name='subject']">
        <xsl:for-each select="xoai:element"> <!-- language -->
          <xsl:for-each select="xoai:field[@name='value']">
            <field name="keyword">
              <xsl:value-of select="."/>
            </field>
          </xsl:for-each>
        </xsl:for-each>
      </xsl:for-each>

      <!-- date -->
      <xsl:for-each select="xoai:element[@name='date']">
        <xsl:for-each select="xoai:element[@name='issued']">
          <xsl:for-each select="xoai:element"> <!-- language -->
            <xsl:for-each select="xoai:field[@name='value']">
              <field name="cdate">
                <xsl:value-of select="."/><xsl:text>T00:00:00Z</xsl:text>
              </field>
            </xsl:for-each>
          </xsl:for-each>
        </xsl:for-each>
      </xsl:for-each>
      
      <!-- title -->
      <xsl:for-each select="xoai:element[@name='title']">
        <xsl:for-each select="xoai:element"> <!-- language -->
          <xsl:for-each select="xoai:field[@name='value']">
            <field name="title">
              <xsl:value-of select="."/>
            </field>
          </xsl:for-each>
        </xsl:for-each>
      </xsl:for-each>

      <!-- abstract -->
      <xsl:for-each select="xoai:element[@name='description']">
        <xsl:for-each select="xoai:element[@name='abstract']">
          <xsl:for-each select="xoai:element"> <!-- language -->
            <xsl:for-each select="xoai:field[@name='value']">
              <field name="title">
                <xsl:value-of select="."/>
              </field>
            </xsl:for-each>
          </xsl:for-each>
        </xsl:for-each>
      </xsl:for-each>

      <!-- LOAR URI -->
      <xsl:for-each select="xoai:element[@name='identifier']">
        <xsl:for-each select="xoai:element[@name='uri']">
          <xsl:for-each select="xoai:element"> <!-- none -->
            <xsl:for-each select="xoai:field[@name='value']">
              <field name="loar_uri">
                <xsl:value-of select="."/>
              </field>
            </xsl:for-each>
          </xsl:for-each>
        </xsl:for-each>
      </xsl:for-each>

      <!-- external PDF -->
      <xsl:for-each select="xoai:element[@name='relation']">
        <xsl:for-each select="xoai:element[@name='uri']">
          <xsl:for-each select="xoai:element"> <!-- none -->
            <xsl:for-each select="xoai:field[@name='value']">
              <field name="external_resource">
                <xsl:value-of select="."/>
              </field>
            </xsl:for-each>
          </xsl:for-each>
        </xsl:for-each>
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

  
