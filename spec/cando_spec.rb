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
    it { expect{ CanDo.connect("sqlite::memory:") }.to raise_error(CanDo::ConfigMysqlDBError) }
    it { CanDo.connect(ENV['CANDO_TEST_DB']).test_connection be_true }
  end

  context "CanDo.init" do
    context "CanDo.cannot_block called from config" do
      it { expect{ CanDo.init{ cannot_block }}.to raise_error(CanDo::ConfigCannotBlockError) }
    end
  end

  context CanDo do
    include CanDo

    context "CanDo#define_role" do
      context "empty role (no capabilities)" do
        it { expect{ define_role("role", []) }.to change{CanDo::Role.count}.from(0).to(1) }
        it { expect{ define_role("role", []) }.to change{CanDo::Capability.count}.by(0) }
      end

      context "standard situation" do
        it { expect{ define_role("role", [:capability1, :capability2]) }.to change{CanDo::Role.count}.from(0).to(1) }
        it { expect{ define_role("role", [:capability1, :capability2]) }.to change{CanDo::Capability.count}.from(0).to(2) }
      end

      context "duplication" do
        before(:each) { define_role("role", [:capability]) }

        it { expect{ define_role("role", [:new_capability]) }.to change{CanDo::Role.count}.by(0) }
        it { expect{ define_role("new_role", [:capability]) }.to change{CanDo::Capability.count}.by(0) }
      end

      context "cleanup" do
        before(:each) do
          @role = define_role("role", [:capabilty])
        end

        it { expect{ @role.destroy }.to change{CanDo::Role.count}.from(1).to(0) }
        it { expect{ @role.destroy }.to change{CanDo::Capability.count}.from(1).to(0) }
      end
    end

    context "CanDo#assign_roles" do
      include CanDo

      context "user without roles" do
        it { expect{ assign_roles("user", []) }.to change{CanDo::User.count}.from(0).to(1) }
        it { expect{ assign_roles("user", []) }.to change{CanDo::Role.count}.by(0) }
      end

      context "invalid roles" do
        it { expect{ assign_roles("user", ["non-existant-role"]) }.to raise_error(CanDo::UndefinedRole) }
        it { expect{ assign_roles("user", [nil]) }.to raise_error(CanDo::UndefinedRole) }
      end

      context "standard situation" do
        before(:each) do
          @r1 = define_role("r1", [:c1, :c2])
          @r2 = define_role("r2", [:c2, :c3])
        end

        it { expect{ assign_roles("user", ["r1"]) }.to change{CanDo::User.count}.from(0).to(1) }
        it { expect{ assign_roles("user", ["r1","r2"]) }.to change{CanDo::User.count}.from(0).to(1) }

        it { expect{ assign_roles("user", [@r1]) }.to change{CanDo::User.count}.from(0).to(1) }
        it { expect{ assign_roles("user", ["r1",@r2]) }.to change{CanDo::User.count}.from(0).to(1) }
      end

      context "cleanup" do
        before(:each) do
          @role = define_role("role", [:capabilty])
          @user = assign_roles("user", [@role])
        end

        it { expect{ @user.destroy }.to change{CanDo::User.count}.from(1).to(0) }
        it { expect{ @user.destroy }.to change{CanDo::Role.count}.by(0) }
      end
    end

    context "CanDo#can" do
      include CanDo

      before(:each) do
        @role = define_role("role", [:capability1, :capabilty2])
        @user = assign_roles("user", [@role])
      end

      context "CanDo#can" do
        it { can("user", :capability1).should be_true }
        it { can("user", :undefined_capability).should be_false }

        it { expect{ |can| can("user", :capability1, &can) }.to yield_control }

        context "CanDo.cannot_block" do
          class DummyException < RuntimeError; end
          before(:all) do
            CanDo.cannot_block do |user, capabilty|
              raise DummyException
            end
          end

          it { expect{ can("user", :undefined_capability){} }.to raise_error(DummyException) }
          it { expect{ can("user", :undefined_capability)}.to_not raise_error(DummyException) }
        end
      end
    end
  end
end
