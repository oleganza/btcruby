require_relative 'spec_helper'

describe BTC::Diagnostics do

  it "should record messages" do

    BTC::Diagnostics.current.wont_be_nil

    # Due to other tests this may not be nil, so we should not check for it.
    # We also should not clear the state in order to test our recording code against whatever state was there before.
    # BTC::Diagnostics.current.last_message.must_equal nil

    BTC::Diagnostics.current.add_message("msg1")
    BTC::Diagnostics.current.last_message.must_equal "msg1"
    BTC::Diagnostics.current.add_message("msg2")
    BTC::Diagnostics.current.last_message.must_equal "msg2"

    BTC::Diagnostics.current.record do

      BTC::Diagnostics.current.record do
        BTC::Diagnostics.current.add_message("a")
        BTC::Diagnostics.current.add_message("b")
        BTC::Diagnostics.current.last_message.must_equal "b"
      end.map(&:to_s).must_equal ["a", "b"]

      BTC::Diagnostics.current.last_message.must_equal "b"

      BTC::Diagnostics.current.add_message("c")

      BTC::Diagnostics.current.record do
        BTC::Diagnostics.current.add_message("d")
        BTC::Diagnostics.current.add_message("e")
      end.map(&:to_s).must_equal ["d", "e"]

    end.map(&:to_s).must_equal ["a", "b", "c", "d", "e"]

    BTC::Diagnostics.current.last_message.must_equal "e"

  end

end
