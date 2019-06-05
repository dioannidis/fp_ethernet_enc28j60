# Free Pascal Ethernet ENC28J60
Free Pascal ENC28J60 driver.

Currently the driver configure the ENC28J60 Ethernet Controller and receives only the Broadcast ARP messages. 

Because an Arduino UNO is used for development, the SPI and UART communication are specific for the ATMEGA328P MCU.

The demo project shows how anyone can use the chip in polling mode or using the interrupt pin of the ENC28J60 via a pin change interrupt on the ATMEGA328P ( enabled or disabled with FP_ENC28J60_USEINTERRUPT define in the project ).

You'll need a recent FPC trunk ( after 4 May 2019 ) as a bunch of issues regarding AVR are fixed.

