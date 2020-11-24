 

pragma solidity ^0.4.13;


 
contract Ownable {
  address public owner;


   
  function Ownable() {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

}

 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) constant returns (uint256);
  function transfer(address to, uint256 value) returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}


 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) returns (bool);
  function approve(address spender, uint256 value) returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

 
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


 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

   
  function transfer(address _to, uint256 _value) returns (bool) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) constant returns (uint256 balance) {
    return balances[_owner];
  }

}


 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) allowed;


   
  function transferFrom(address _from, address _to, uint256 _value) returns (bool) {
    var _allowance = allowed[_from][msg.sender];

     
     

    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) returns (bool) {

     
     
     
     
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

}



contract CRCToken is StandardToken,Ownable{
	 
	string public name;
	string public symbol;
	string public constant version = "1.0";
	uint256 public constant decimals = 18;

	uint256 public constant MAX_SUPPLY = 500000000 * 10**decimals;
	uint256 public constant quota = MAX_SUPPLY/100;

	 
	uint256 public constant allOfferingPercentage = 50;
	uint256 public constant teamKeepingPercentage = 15;
	uint256 public constant communityContributionPercentage = 35;

	 
	uint256 public constant allOfferingQuota = quota*allOfferingPercentage;
	uint256 public constant teamKeepingQuota = quota*teamKeepingPercentage;
	uint256 public constant communityContributionQuota = quota*communityContributionPercentage;

	 
	 
	uint256 public constant privateOfferingPercentage = 10;
	uint256 public constant privateOfferingCap = quota*privateOfferingPercentage;

	 
	uint256 public constant publicOfferingExchangeRate = 25000;
	uint256 public constant privateOfferingExchangeRate = 50000;

	 
	address public etherProceedsAccount;
	address public crcWithdrawAccount;

	 
	uint256 public fundingStartBlock;
	uint256 public fundingEndBlock;
	uint256 public teamKeepingLockEndBlock ;

	uint256 public privateOfferingSupply;
	uint256 public allOfferingSupply;
	uint256 public teamWithdrawSupply;
	uint256 public communityContributionSupply;



	 

	event CreateCRC(address indexed _to, uint256 _value);

	 

	function CRCToken(){
		name = "CRCToken";
		symbol ="CRC";

		etherProceedsAccount = 0x5390f9D18A7131aC9C532C1dcD1bEAb3e8A44cbF;
		crcWithdrawAccount = 0xb353425bA4FE2670DaC1230da934498252E692bD;

		fundingStartBlock=4263161;
		fundingEndBlock=4313561;
		teamKeepingLockEndBlock=5577161;

		totalSupply = 0 ;
		privateOfferingSupply=0;
		allOfferingSupply=0;
		teamWithdrawSupply=0;
		communityContributionSupply=0;
	}


	modifier beforeFundingStartBlock(){
		assert(getCurrentBlockNum() < fundingStartBlock);
		_;
	}

	modifier notBeforeFundingStartBlock(){
		assert(getCurrentBlockNum() >= fundingStartBlock);
		_;
	}
	modifier notAfterFundingEndBlock(){
		assert(getCurrentBlockNum() < fundingEndBlock);
		_;
	}
	modifier notBeforeTeamKeepingLockEndBlock(){
		assert(getCurrentBlockNum() >= teamKeepingLockEndBlock);
		_;
	}

	modifier totalSupplyNotReached(uint256 _ethContribution,uint rate){
		assert(totalSupply.add(_ethContribution.mul(rate)) <= MAX_SUPPLY);
		_;
	}
	modifier allOfferingNotReached(uint256 _ethContribution,uint rate){
		assert(allOfferingSupply.add(_ethContribution.mul(rate)) <= allOfferingQuota);
		_;
	}	 

	modifier privateOfferingCapNotReached(uint256 _ethContribution){
		assert(privateOfferingSupply.add(_ethContribution.mul(privateOfferingExchangeRate)) <= privateOfferingCap);
		_;
	}	 
	

	modifier etherProceedsAccountOnly(){
		assert(msg.sender == getEtherProceedsAccount());
		_;
	}
	modifier crcWithdrawAccountOnly(){
		assert(msg.sender == getCrcWithdrawAccount());
		_;
	}




	function processFunding(address receiver,uint256 _value,uint256 fundingRate) internal
		totalSupplyNotReached(_value,fundingRate)
		allOfferingNotReached(_value,fundingRate)

	{
		uint256 tokenAmount = _value.mul(fundingRate);
		totalSupply=totalSupply.add(tokenAmount);
		allOfferingSupply=allOfferingSupply.add(tokenAmount);
		balances[receiver] += tokenAmount;   
		CreateCRC(receiver, tokenAmount);	  
	}


	function () payable external{
		if(getCurrentBlockNum()<=fundingStartBlock){
			processPrivateFunding(msg.sender);
		}else{
			processEthPulicFunding(msg.sender);
		}


	}

	function processEthPulicFunding(address receiver) internal
	 notBeforeFundingStartBlock
	 notAfterFundingEndBlock
	{
		processFunding(receiver,msg.value,publicOfferingExchangeRate);
	}
	

	function processPrivateFunding(address receiver) internal
	 beforeFundingStartBlock
	 privateOfferingCapNotReached(msg.value)
	{
		uint256 tokenAmount = msg.value.mul(privateOfferingExchangeRate);
		privateOfferingSupply=privateOfferingSupply.add(tokenAmount);
		processFunding(receiver,msg.value,privateOfferingExchangeRate);
	}  

	function icoPlatformWithdraw(uint256 _value) external
		crcWithdrawAccountOnly
	{
		processFunding(msg.sender,_value,1);
	}

	function teamKeepingWithdraw(uint256 tokenAmount) external
	   crcWithdrawAccountOnly
	   notBeforeTeamKeepingLockEndBlock
	{
		assert(teamWithdrawSupply.add(tokenAmount)<=teamKeepingQuota);
		assert(totalSupply.add(tokenAmount)<=MAX_SUPPLY);
		teamWithdrawSupply=teamWithdrawSupply.add(tokenAmount);
		totalSupply=totalSupply.add(tokenAmount);
		balances[msg.sender]+=tokenAmount;
		CreateCRC(msg.sender, tokenAmount);
	}

	function communityContributionWithdraw(uint256 tokenAmount) external
	    crcWithdrawAccountOnly
	{
		assert(communityContributionSupply.add(tokenAmount)<=communityContributionQuota);
		assert(totalSupply.add(tokenAmount)<=MAX_SUPPLY);
		communityContributionSupply=communityContributionSupply.add(tokenAmount);
		totalSupply=totalSupply.add(tokenAmount);
		balances[msg.sender] += tokenAmount;
		CreateCRC(msg.sender, tokenAmount);
	}

	function etherProceeds() external
		etherProceedsAccountOnly
	{
		if(!msg.sender.send(this.balance)) revert();
	}
	



	function getCurrentBlockNum()  internal returns (uint256){
		return block.number;
	}

	function getEtherProceedsAccount() internal  returns (address){
		return etherProceedsAccount;
	}


	function getCrcWithdrawAccount() internal returns (address){
		return crcWithdrawAccount;
	}

	function setName(string _name) external
		onlyOwner
	{
		name=_name;
	}

	function setSymbol(string _symbol) external
		onlyOwner
	{
		symbol=_symbol;
	}


	function setEtherProceedsAccount(address _etherProceedsAccount) external
		onlyOwner
	{
		etherProceedsAccount=_etherProceedsAccount;
	}

	function setCrcWithdrawAccount(address _crcWithdrawAccount) external
		onlyOwner
	{
		crcWithdrawAccount=_crcWithdrawAccount;
	}

	function setFundingBlock(uint256 _fundingStartBlock,uint256 _fundingEndBlock,uint256 _teamKeepingLockEndBlock) external
		onlyOwner
	{

		fundingStartBlock=_fundingStartBlock;
		fundingEndBlock = _fundingEndBlock;
		teamKeepingLockEndBlock = _teamKeepingLockEndBlock;
	}


}