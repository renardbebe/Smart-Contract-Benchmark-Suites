 

 

pragma solidity ^0.4.16;

library SafeMath {
    function mul(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }
    
    function div(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a / b;
        return c;
    }
    
    function sub(uint256 a, uint256 b) internal constant returns (uint256) {
        assert(b <= a);
        return a - b;
    }
    
    function add(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}
contract Ownable {
      

  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

   
  function Ownable(address _owner){
    owner = _owner;
  }

   
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
  
   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

}
contract ReentrancyGuard {

   
  bool private rentrancy_lock = false;

   
  modifier nonReentrant() {
    require(!rentrancy_lock);
    rentrancy_lock = true;
    _;
    rentrancy_lock = false;
  }

}
contract Pausable is Ownable {
  
  event Pause(bool indexed state);

  bool private paused = false;

   
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

   
  modifier whenPaused() {
    require(paused);
    _;
  }

   
  function Paused() external constant returns(bool){ return paused; }

   
  function tweakState() external onlyOwner {
    paused = !paused;
    Pause(paused);
  }

}
contract Allocations{

	 
  	uint256 private releaseTime;

	mapping (address => uint256) private allocations;

	function Allocations(){
		releaseTime = now + 198 days;
		allocate();
	}

	 
    function allocate() private {
      allocations[0xab1cb1740344A9280dC502F3B8545248Dc3045eA] = 4000000 * 1 ether;
      allocations[0x330709A59Ab2D1E1105683F92c1EE8143955a357] = 4000000 * 1 ether;
      allocations[0xAa0887fc6e8896C4A80Ca3368CFd56D203dB39db] = 3000000 * 1 ether;
      allocations[0x1fbA1d22435DD3E7Fa5ba4b449CC550a933E72b3] = 200000 * 1 ether;
      allocations[0xC9d5E2c7e40373ae576a38cD7e62E223C95aBFD4] = 200000 * 1 ether;
      allocations[0xabc0B64a38DE4b767313268F0db54F4cf8816D9C] = 220000 * 1 ether;
      allocations[0x5d85bCDe5060C5Bd00DBeDF5E07F43CE3Ccade6f] = 50000 * 1 ether;
      allocations[0xecb1b0231CBC0B04015F9e5132C62465C128B578] = 500000 * 1 ether;
      allocations[0xFF22FA2B3e5E21817b02a45Ba693B7aC01485a9C] = 2955000 * 1 ether;
    }

	 
	function release() internal returns (uint256 amount){
		amount = allocations[msg.sender];
		allocations[msg.sender] = 0;
		return amount;
	}

	 
	function RealeaseTime() external constant returns(uint256){ return releaseTime; }

    modifier timeLock() { 
		require(now >= releaseTime);
		_; 
	}

	modifier isTeamMember() { 
		require(allocations[msg.sender] >= 10000 * 1 ether); 
		_; 
	}

}

contract NotaryPlatformToken is Pausable, Allocations, ReentrancyGuard{

  using SafeMath for uint256;

  string constant public name = "Notary Platform Token";
  string constant public symbol = "NTRY";
  uint8 constant public decimals = 18;
  uint256 public totalSupply = 150000000 * 1 ether;
  string constant version = "v1.0.1";

  mapping(address => uint256) private balances;
  mapping (address => mapping (address => uint256)) private allowed;

  event Approval(address indexed owner, address indexed spender, uint256 value);
  event Transfer(address indexed from, address indexed to, uint256 value);

  function NotaryPlatformToken() Ownable(0x1538EF80213cde339A333Ee420a85c21905b1b2D){
     
    balances[0x244092a2FECFC48259cf810b63BA3B3c0B811DCe] = 134875000 * 1 ether;
    require(ICOParticipants(0x244092a2FECFC48259cf810b63BA3B3c0B811DCe));
  }


   

   
  function transfer(address _to, uint256 _value) external whenNotPaused onlyPayloadSize(2 * 32) returns (bool) {
    require(_to != address(0));
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) external constant returns (uint256 balance) {
    return balances[_owner];
  }

   
  function transferFrom(address _from, address _to, uint256 _value) external whenNotPaused returns (bool) {
    require(_to != address(0));

    uint256 _allowance = allowed[_from][msg.sender];

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) external whenNotPaused returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) external constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval (address _spender, uint _addedValue) external whenNotPaused returns (bool success) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval (address _spender, uint _subtractedValue) external whenNotPaused returns (bool success) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function claim() external whenNotPaused nonReentrant timeLock isTeamMember {
    balances[msg.sender] = balances[msg.sender].add(release());
  }

   
  uint256 public totalMigrated;
  bool private upgrading = false;
  MigrationAgent private agent;
  event Migrate(address indexed _from, address indexed _to, uint256 _value);
  event Upgrading(bool status);

  function migrationAgent() external constant returns(address){ return agent; }
  function upgradingEnabled()  external constant returns(bool){ return upgrading; }

   
  function migrate(uint256 _value) external nonReentrant isUpgrading {
    require(_value > 0);
    require(_value <= balances[msg.sender]);
    require(agent.isMigrationAgent());

    balances[msg.sender] = balances[msg.sender].sub(_value);
    totalSupply = totalSupply.sub(_value);
    totalMigrated = totalMigrated.add(_value);
    
    if(!agent.migrateFrom(msg.sender, _value)){
      revert();
    }
    Migrate(msg.sender, agent, _value);
  }

   
  function setMigrationAgent(address _agent) external isUpgrading onlyOwner {
    require(_agent != 0x00);
    agent = MigrationAgent(_agent);
    if(!agent.isMigrationAgent()){
      revert();
    }
    
    if(agent.originalSupply() != totalSupply){
      revert();
    }
  }

   
  function tweakUpgrading() external onlyOwner{
      upgrading = !upgrading;
      Upgrading(upgrading);
  }


   
  function isTokenContract() external constant returns (bool) {
    return true;
  }

  modifier isUpgrading() { 
    require(upgrading); 
    _; 
  }


   
  modifier onlyPayloadSize(uint size) {
     require(msg.data.length == size + 4);
     _;
  }

  function () {
     
    revert();
  }
  
  

   function ICOParticipants(address _supplyOwner) private returns(bool){
         
        balances[0xd0780ab2aa7309e139a1513c49fb2127ddc30d3d] = 15765750000000000000000;
        balances[0x196a484db36d2f2049559551c182209143db4606] = 2866500000000000000000;
        balances[0x36cfb5a6be6b130cfceb934d3ca72c1d72c3a7d8] = 28665000000000000000000;
        balances[0x21c4ff1738940b3a4216d686f2e63c8dbcb7dc44] = 2866500000000000000000;
        balances[0xd1f3a1a16f4ab35e5e795ce3f49ee2dff2dd683b] = 1433250000000000000000;
        balances[0xd45bf2debd1c4196158dcb177d1ae910949dc00a] = 5733000000000000000000;
        balances[0xdc5984a2673c46b68036076026810ffdffb695b8] = 1433250000000000000000;
        balances[0x6ee541808c463116a82d76649da0502935fa8d08] = 57330000000000000000000;
        balances[0xde3270049c833ff2a52f18c7718227eb36a92323] = 4948241046840000000000;
        balances[0x51a51933721e4ada68f8c0c36ca6e37914a8c609] = 17199000000000000000000;
        balances[0x737069e6f9f02062f4d651c5c8c03d50f6fc99c6] = 2866500000000000000000;
        balances[0xa6a14a81ec752e0ed5391a22818f44aa240ffbb1] = 2149875000000000000000;
        balances[0xeac8483261078517528de64956dbd405f631265c] = 11466000000000000000000;
        balances[0x7736154662ba56c57b2be628fe0e44a609d33dfb] = 2866500000000000000000;
        balances[0xc1c113c60ebf7d92a3d78ff7122435a1e307ce05] = 5733000000000000000000;
        balances[0xfffdfaef43029d6c749ceff04f65187bd50a5311] = 2293200000000000000000;
        balances[0x8854f86f4fbd88c4f16c4f3d5a5500de6d082adc] = 2866500000000000000000;
        balances[0x26c32811447c8d0878b2dae7f4538ae32de82d57] = 2436525000000000000000;
        balances[0xe752737dd519715ab0fa9538949d7f9249c7c168] = 2149875000000000000000;
        balances[0x01ed3975993c8bebff2fb6a7472679c6f7b408fb] = 11466000000000000000000;
        balances[0x7924c67c07376cf7c4473d27bee92fe82dfd26c5] = 11466000000000000000000;
        balances[0xf360b24a530d29c96a26c2e34c0dabcab12639f4] = 8599500000000000000000;
        balances[0x6a7f63709422a986a953904c64f10d945c8afba1] = 2866500000000000000000;
        balances[0xa68b4208e0b7aacef5e7cf8d6691d5b973bad119] = 2149875000000000000000;
        balances[0xb9bd4f154bb5f2be5e7db0357c54720c7f35405d] = 2149875000000000000000;
        balances[0x6723f81cdc9a5d5ef2fe1bfbedb4f83bd017d3dc] = 5446350000000000000000;
        balances[0x8f066f3d9f75789d9f126fdd7cfbcc38a768985d] = 146737500000000000000000;
        balances[0xf49c6e7e36a714bbc162e31ca23a04e44dcaf567] = 25769835000000000000000;
        balances[0x1538ef80213cde339a333ee420a85c21905b1b2d] = 2730000000000000000000;
        balances[0x81a837cc83b55a67351c1070920f061dda307348] = 25511850000000000000000;
        balances[_supplyOwner] -= 417961751000000000000000;
        return true;
 	}

}

 
contract MigrationAgent {

  uint256 public originalSupply;
  
  function migrateFrom(address _from, uint256 _value) external returns(bool);
  
   
  function isMigrationAgent() external constant returns (bool) {
    return true;
  }
}