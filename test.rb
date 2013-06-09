require "serialport"

PORT_NAME = "COM5"

class PSR600
  STX = 2
  ETX = 3

  KEY_TO_CODE = {
    :ARROW_DOWN  => 9,
    :ARROW_LEFT  => 14,
    :ARROW_RIGHT => 2,
    :ARROW_UP    => 7,
    :ATT         => 26,
    :CLR         => 36,
    :DIM         => 32,
    :ENT         => 18,
    :F1          => 31,
    :F2          => 25,
    :F3          => 19,
    :FAV         => 4,
    :FUNC        => 1,
    :L_OUT       => 5,
    :MAN         => 3,
    :NUM_0       => 30,
    :NUM_1       => 33,
    :NUM_2       => 27,
    :NUM_3       => 21,
    :NUM_4       => 34,
    :NUM_5       => 28,
    :NUM_6       => 22,
    :NUM_7       => 35,
    :NUM_8       => 29,
    :NUM_9       => 23,
    :PAUSE       => 6,
    :PERIOD      => 24,
    :PGM         => 12,
    :PRI         => 11,
    :SCAN        => 15,
    :SEL         => 8,
    :SRCH        => 10,
    :TUNE        => 16,
    :WX          => 17,
  }

  def initialize(port_name)
    @port = SerialPort.new(port_name, 115200, 8, 1, SerialPort::NONE)
  end

  def get_status
    send_message(make_message_bytes("A".ord))
    Status.new(receive_response)
  end

  def get_lcd
    send_message(make_message_bytes("L".ord))
    LCD.new(receive_response)
  end

  def send_key(key)
    code = KEY_TO_CODE[key]
    send_message(make_message_bytes("K".ord, [code]))
    nil
  end

  def tune(frequency)
    send_message(make_message_bytes("T".ord, [0, 0, 0, 0, 0]))
    nil
  end

  class Status
    def initialize(bs)
      @bs = bs
    end
  end

  class LCD
    def initialize(bs)
      @bs = bs
    end
  end

  private

  def calc_checksum(bs)
    bs[1..-1].inject(0){|sum,e| sum + e} & 0xff
  end

  def make_message_bytes(cb, dbs=nil)
    bs = []
    bs << STX
    bs << cb
    bs += dbs if dbs
    bs << ETX
    bs << calc_checksum(bs)
  end

  def send_message(bs)
    m = bs.map(&:chr).join
    @port.write(m)
  end

  def receive_response
    bs = []
    bs << b = @port.readbyte
    raise "no STX" unless b == STX
    loop do
      bs << b = @port.readbyte
      break if b == ETX
    end
    cs  = @port.readbyte
    ccs = calc_checksum(bs)
    if cs != ccs
      raise "checksum #{"%#02x" % cs} != calc'd checksum #{"%#02x" % ccs}"
    end
    bs[1..-2]
  end
end

if $0 == __FILE__
  psr600 = PSR600.new(PORT_NAME)
  p psr600.get_status
  p psr600.get_lcd
  p psr600.send_key(:PAUSE)
end
