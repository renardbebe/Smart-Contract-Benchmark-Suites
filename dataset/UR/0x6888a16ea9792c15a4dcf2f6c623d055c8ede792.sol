 

pragma solidity ^0.4.15;

 
library SafeMath {
    function safeMul(uint a, uint b) internal returns (uint) {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function safeDiv(uint a, uint b) internal returns (uint) {
        assert(b > 0);
        uint c = a / b;
        assert(a == b * c + a % b);
        return c;
    }

    function safeSub(uint a, uint b) internal returns (uint) {
        assert(b <= a);
        return a - b;
    }

    function safeAdd(uint a, uint b) internal returns (uint) {
        uint c = a + b;
        assert(c>=a && c>=b);
        return c;
    }

    function max64(uint64 a, uint64 b) internal constant returns (uint64) {
        return a >= b ? a : b;
    }

    function min64(uint64 a, uint64 b) internal constant returns (uint64) {
        return a < b ? a : b;
    }

    function max256(uint256 a, uint256 b) internal constant returns (uint256) {
        return a >= b ? a : b;
    }

    function min256(uint256 a, uint256 b) internal constant returns (uint256) {
        return a < b ? a : b;
    }
}


 
contract ERC20 {
    uint public totalSupply;
    function balanceOf(address who) constant returns (uint);
    function allowance(address owner, address spender) constant returns (uint);

    function transfer(address to, uint value) returns (bool ok);
    function transferFrom(address from, address to, uint value) returns (bool ok);
    function approve(address spender, uint value) returns (bool ok);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}



 
contract StandardToken is ERC20
{
    using SafeMath for uint;

    mapping(address => uint) balances;
    mapping(address => mapping (address => uint)) allowed;

     
    bool public constant isToken = true;

     
    modifier onlyPayloadSize(uint size) {
        require(msg.data.length == size + 4);
        _;
    }

    function transfer(address _to, uint _value)
        onlyPayloadSize(2 * 32)
        returns (bool success)
    {
        balances[msg.sender] = balances[msg.sender].safeSub(_value);
        balances[_to] = balances[_to].safeAdd(_value);

        Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address from, address to, uint value)
        returns (bool success)
    {
        uint _allowance = allowed[from][msg.sender];

         
         

        balances[to] = balances[to].safeAdd(value);
        balances[from] = balances[from].safeSub(value);
        allowed[from][msg.sender] = _allowance.safeSub(value);

        Transfer(from, to, value);
        return true;
    }

    function balanceOf(address account)
        constant
        returns (uint balance)
    {
        return balances[account];
    }

    function approve(address spender, uint value)
        returns (bool success)
    {
         
         
         
         
        if ((value != 0) && (allowed[msg.sender][spender] != 0)) throw;

        allowed[msg.sender][spender] = value;

        Approval(msg.sender, spender, value);
        return true;
    }

    function allowance(address account, address spender)
        constant
        returns (uint remaining)
    {
        return allowed[account][spender];
    }
}



 
contract UpgradeTarget
{
    uint public originalSupply;

     
    function isUpgradeTarget() public constant returns (bool) {
        return true;
    }

    function upgradeFrom(address _from, uint256 _value) public;
}


 
contract UpgradeableToken is StandardToken
{
     
    address public upgradeMaster;

     
    UpgradeTarget public upgradeTarget;

     
    uint256 public totalUpgraded;

     
    enum UpgradeState {Unknown, NotAllowed, WaitingForAgent, ReadyToUpgrade, Upgrading}

     
    event LogUpgrade(address indexed _from, address indexed _to, uint256 _value);

     
    event LogSetUpgradeTarget(address agent);

     
    function UpgradeableToken(address _upgradeMaster) {
        upgradeMaster = _upgradeMaster;
    }

     
    function upgrade(uint256 value) public {
        UpgradeState state = getUpgradeState();
        require(state == UpgradeState.ReadyToUpgrade || state == UpgradeState.Upgrading);

         
        require(value > 0);

        balances[msg.sender] = balances[msg.sender].safeSub(value);

         
        totalSupply   = totalSupply.safeSub(value);
        totalUpgraded = totalUpgraded.safeAdd(value);

         
        upgradeTarget.upgradeFrom(msg.sender, value);
        LogUpgrade(msg.sender, upgradeTarget, value);
    }

     
    function setUpgradeTarget(address target) external {
        require(canUpgrade());
        require(target != 0x0);
        require(msg.sender == upgradeMaster);  
        require(getUpgradeState() != UpgradeState.Upgrading);  

        upgradeTarget = UpgradeTarget(target);

        require(upgradeTarget.isUpgradeTarget());  
        require(upgradeTarget.originalSupply() == totalSupply);  

        LogSetUpgradeTarget(upgradeTarget);
    }

     
    function getUpgradeState() public constant returns (UpgradeState) {
        if (!canUpgrade()) return UpgradeState.NotAllowed;
        else if (address(upgradeTarget) == 0x00) return UpgradeState.WaitingForAgent;
        else if (totalUpgraded == 0) return UpgradeState.ReadyToUpgrade;
        else return UpgradeState.Upgrading;
    }

     
    function setUpgradeMaster(address master) public {
        require(master != 0x0);
        require(msg.sender == upgradeMaster);

        upgradeMaster = master;
    }

     
    function canUpgrade() public constant returns (bool) {
        return true;
    }
}

contract MintableToken is StandardToken
{
    address public mintMaster;

    event LogMintTokens(address recipient, uint amount, uint newBalance, uint totalSupply);
    event LogUnmintTokens(address hodler, uint amount, uint newBalance, uint totalSupply);
    event LogSetMintMaster(address oldMintMaster, address newMintMaster);

    function MintableToken(address _mintMaster) {
        mintMaster = _mintMaster;
    }

    function setMintMaster(address newMintMaster)
        returns (bool ok)
    {
        require(msg.sender == mintMaster);

        address oldMintMaster = mintMaster;
        mintMaster = newMintMaster;

        LogSetMintMaster(oldMintMaster, mintMaster);
        return true;
    }

    function mintTokens(address recipient, uint amount)
        returns (bool ok)
    {
        require(msg.sender == mintMaster);
        require(amount > 0);

        balances[recipient] = balances[recipient].safeAdd(amount);
        totalSupply = totalSupply.safeAdd(amount);

        LogMintTokens(recipient, amount, balances[recipient], totalSupply);
        Transfer(address(0), recipient, amount);
        return true;
    }

    function unmintTokens(address hodler, uint amount)
        returns (bool ok)
    {
        require(msg.sender == mintMaster);
        require(amount > 0);
        require(balances[hodler] >= amount);

        balances[hodler] = balances[hodler].safeSub(amount);
        totalSupply = totalSupply.safeSub(amount);

        LogUnmintTokens(hodler, amount, balances[hodler], totalSupply);
        Transfer(hodler, address(0), amount);
        return true;
    }
}


contract SigToken is UpgradeableToken, MintableToken
{
    string public name = "Signals";
    string public symbol = "SIG";
    uint8 public decimals = 18;

    address public crowdsaleContract;
    bool public crowdsaleCompleted;

    function SigToken()
        UpgradeableToken(msg.sender)
        MintableToken(msg.sender)
    {
        crowdsaleContract = msg.sender;
        totalSupply = 0;  
    }

    function transfer(address _to, uint _value)
        returns (bool success)
    {
        require(crowdsaleCompleted);
        return StandardToken.transfer(_to, _value);
    }

    function transferFrom(address from, address to, uint value)
        returns (bool success)
    {
        require(crowdsaleCompleted);
        return StandardToken.transferFrom(from, to, value);
    }

    function approve(address spender, uint value)
        returns (bool success)
    {
        require(crowdsaleCompleted);
        return StandardToken.approve(spender, value);
    }

     
     
     
    function setCrowdsaleCompleted() {
        require(msg.sender == crowdsaleContract);
        require(crowdsaleCompleted == false);

        crowdsaleCompleted = true;
    }

     
    function approveAndCall(address _spender, uint256 _value, bytes _extraData)
        public
        returns (bool success)
    {
        require(crowdsaleCompleted);

        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);

         
         
         
        require(_spender.call(bytes4(bytes32(keccak256("receiveApproval(address,uint256,address,bytes)"))), msg.sender, _value, this, _extraData));
        return true;
    }
}