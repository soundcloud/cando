require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

#describe "Cando" do
#  it "fails" do
#    fail "hey buddy, you should probably rename this file and start specing for real"
#  end
#end
#
describe CanDo do
  context "CanDo.cannot_block expects block accepting two parameters" do
    it { expect{ CanDo.cannot_block }.to              raise_error(CanDo::ConfigCannotBlockError) }
    it { expect{ CanDo.cannot_block{|x| x} }.to       raise_error(CanDo::ConfigCannotBlockError) }
    it { expect{ CanDo.cannot_block{|x,y,z| x} }.to   raise_error(CanDo::ConfigCannotBlockError) }

    it { expect{ CanDo.cannot_block{|x,y| x} }.to_not raise_error(CanDo::ConfigCannotBlockError) }
  end

  context "CanDo.connect" do
    it { expect{ CanDo.connect(nil) }.to raise_error(CanDo::ConfigMysqlConnectionError) }
    it { expect{ CanDo.connect("sqlite::memory:") }.to_not raise_error(CanDo::ConfigMysqlConnectionError) }
    it { CanDo.connect("sqlite::memory:").test_connection be_true }
  end

  context "CanDo.init" do
    context "CanDo.cannot_block called from config" do
      it { expect{ CanDo.init{ cannot_block }}.to raise_error(CanDo::ConfigCannotBlockError) }
    end
  end
  
end
