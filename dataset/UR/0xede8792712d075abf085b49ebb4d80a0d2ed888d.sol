 

pragma solidity ^0.4.17;

library SafeMath {

     
    function Mul(uint256 a, uint256 b) pure internal returns (uint256) {
      uint256 c = a * b;
       
      assert(a == 0 || c / a == b);
      return c;
    }

     
    function Div(uint256 a, uint256 b) pure internal returns (uint256) {
       
      uint256 c = a / b;
       
      return c;
    }

     
    function Sub(uint256 a, uint256 b) pure internal returns (uint256) {
       
      assert(b <= a);
      return a - b;
    }

     
    function Add(uint256 a, uint256 b) pure internal returns (uint256) {
      uint256 c = a + b;
       
       
      assert(c >= a);
      return c;
    }
}

 
contract ERC20Basic {

   
  uint256 public totalSupply;

   
  function balanceOf(address who) view public returns (uint256);

   
  function transfer(address _to, uint256 _value) public returns(bool ok);

   
  event Transfer(address indexed _from, address indexed _to, uint256 _value);
}

 
contract ERC20 is ERC20Basic {

   
  function allowance(address owner, address spender) public view returns (uint256);

   
  function transferFrom(address _from, address _to, uint256 _value) public returns(bool ok);

   
  function approve(address _spender, uint256 _value) public returns(bool ok);

   
  event Approval(address indexed owner, address indexed spender, uint256 value);
}


 
contract Ownable {

   
  address public owner;

   
  function Ownable() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require (msg.sender == owner);
      _;
  }

   
  function transferOwnership(address newOwner) public onlyOwner {
    require (newOwner != address(0));
      owner = newOwner;
  }

}

 
contract Pausable is Ownable {

   
  bool public stopped;

   
  event StateChanged(bool changed);

   
  modifier stopInEmergency {
    require(!stopped);
    _;
  }

   
  modifier onlyInEmergency {
    require(stopped);
    _;
  }

   
  function emergencyStop() external onlyOwner  {
    stopped = true;
     
    StateChanged(true);
  }

   
  function release() external onlyOwner onlyInEmergency {
    stopped = false;
     
    StateChanged(true);
  }

}

 
contract Injii is ERC20, Ownable {

  using SafeMath for uint256;

   
   
  string public constant name = "Injii Access Coins";

   
  string public constant symbol = "IAC";

   
  uint8 public constant decimals = 0;

   
  string public version = 'v1.0';

   
  bool public locked;

   
  mapping(address => uint256) balances;

   
  mapping (address => mapping (address => uint256)) allowed;

   
  modifier onlyPayloadSize(uint256 size) {
     require(msg.data.length >= size + 4);
     _;
  }

   
  modifier onlyUnlocked() {
    require(!locked);
    _;
  }

   
  function Injii() public {
     
    locked = true;

     
    totalSupply = 0;
  }

   
  function transfer(address _to, uint256 _value) onlyPayloadSize(2 * 32) public onlyUnlocked returns (bool){

     
    if (_to != address(0) && _value >= 1) {
       
      balances[msg.sender] = balances[msg.sender].Sub(_value);
       
      balances[_to] = balances[_to].Add(_value);
       
      Transfer(msg.sender, _to, _value);
      return true;
    }
    else{
      return false;
    }
  }

   
  function transferFrom(address _from, address _to, uint256 _value) onlyPayloadSize(3 * 32) public onlyUnlocked returns (bool) {

     
    if (_to != address(0) && _from != address(0)) {
       
      var _allowance = allowed[_from][msg.sender];
       
      balances[_to] = balances[_to].Add(_value);
       
      balances[_from] = balances[_from].Sub(_value);
       
      allowed[_from][msg.sender] = _allowance.Sub(_value);
       
      Transfer(_from, _to, _value);
      return true;
    }else{
      return false;
    }
  }

   
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    require(_spender != address(0));
     
    uint256 iacToApprove = _value;
    allowed[msg.sender][_spender] = iacToApprove;
     
    Approval(msg.sender, _spender, iacToApprove);
    return true;
  }

   
  function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

}

contract Metadata {
    
    address public owner;
    
    mapping (uint => address) registerMap;

    function Metadata() public {
        owner = msg.sender;
        registerMap[0] = msg.sender;
    }

     
    function getAddress (uint addressId) public view returns (address){
        return registerMap[addressId];
    }

     
     
     
     
     
    function addAddress (uint addressId, address addressContract) public {
        assert(addressContract != 0x0 );
        require (owner == msg.sender || owner == tx.origin);
        registerMap[addressId] = addressContract;
    }
}

contract Ecosystem is Ownable{


    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
     
    Metadata private objMetadata;
    Crowdsale private objCrowdsale;
    uint256 constant private ecosystemContractID = 1;
    uint256 constant private crowdsaleContractID = 2;
    bool public crowdsaleAddressSet;
    event TokensReceived(address receivedFrom, uint256 numberOfTokensReceive);

     
    function Ecosystem(address _metadataContractAddr) public {
        assert(_metadataContractAddr != address(0));
         
        objMetadata = Metadata(_metadataContractAddr);
         
        objMetadata.addAddress(ecosystemContractID, this);
    }

    function SetCrowdsaleAddress () public onlyOwner {
        require(!crowdsaleAddressSet);
        address crowdsaleContractAddress = objMetadata.getAddress(crowdsaleContractID);
        assert(crowdsaleContractAddress != address(0));
        objCrowdsale = Crowdsale(crowdsaleContractAddress);
        crowdsaleAddressSet = true;
    }

    function rewardUser(address user, uint256 iacToSend) public onlyOwner{
        assert(crowdsaleAddressSet);
        objCrowdsale.transfer(user, iacToSend);
    }

    function tokenFallback(address _from, uint _value){
        TokensReceived(_from, _value);
    }

}

contract CompanyInventory is Ownable{
    using SafeMath for uint256;

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
     
    uint256 public startBlock;
     
    uint256 public unlockedTokens;
    uint256 public initialReleaseDone = 0;
    uint256 public secondReleaseDone = 0;
    uint256 public totalSuppliedAfterLock = 0;
    uint256 public balance = 0;
    uint256 public totalSupplyFromInventory;
     
    uint256 public totalRemainInInventory;
     
    Metadata private objMetadata;
    Crowdsale private objCrowdsale;
    uint256 constant private crowdsaleContractID = 2;
    uint256 constant private inventoryContractID = 3;
     
    event TransferredUnlockedTokens(address addr, uint value, bytes32 comment);
     
    event StateChanged(bool changed);
    
     
    function CompanyInventory(address _metadataContractAddr) public {
        assert(_metadataContractAddr != address(0));
         
        objMetadata = Metadata(_metadataContractAddr);
        objMetadata.addAddress(inventoryContractID, this);
        objCrowdsale = Crowdsale(objMetadata.getAddress(crowdsaleContractID));
    }
    
    function initiateLocking (uint256 _alreadyTransferredTokens) public {
        require(msg.sender == objMetadata.getAddress(crowdsaleContractID) && startBlock == 0);
        startBlock = now;
        unlockedTokens = 0;
        balance = objCrowdsale.balanceOf(this);
        totalSupplyFromInventory = _alreadyTransferredTokens;
        totalRemainInInventory = balance.Add(_alreadyTransferredTokens).Sub(_alreadyTransferredTokens);
        StateChanged(true);
    }
    
    function releaseTokens () public onlyOwner {
        require(startBlock > 0);
        if(initialReleaseDone == 0){
            require(now >= startBlock.Add(1 years));
            unlockedTokens =  balance/2;
            initialReleaseDone = 1;
        }
        else if(secondReleaseDone == 0){
            require(now >= startBlock.Add(2 years));
            unlockedTokens = balance;
            secondReleaseDone = 1;
        }
        StateChanged(true);
    }
    
     
    function TransferFromCompanyInventory(address beneficiary,uint256 iacToCredit,bytes32 comment) onlyOwner external {
        require(beneficiary != address(0));
        require(totalSuppliedAfterLock.Add(iacToCredit) <= unlockedTokens);
        objCrowdsale.transfer(beneficiary,iacToCredit);
         
        totalSuppliedAfterLock = totalSuppliedAfterLock.Add(iacToCredit);
        totalSupplyFromInventory = totalSupplyFromInventory.Add(iacToCredit);
         
        totalRemainInInventory = totalRemainInInventory.Sub(iacToCredit);
         
        TransferredUnlockedTokens(beneficiary, iacToCredit, comment);
         
        StateChanged(true);
    }
}

contract Crowdsale is Injii, Pausable {
    using SafeMath for uint256;
     
    uint256 public startBlock;
     
    uint256 public constant durationCrowdSale = 25 days;
     
    uint256 public constant gapInPrimaryCrowdsaleAndSecondaryCrowdsale = 2 years;
     
    uint256 public endBlock;

     
    uint256 public constant maxCapCompanyInventory = 250e6;
     
    uint256 public constant maxCap = 500e6;
    uint256 public constant maxCapEcosystem = 250e6;
    uint256 public constant numberOfTokensToAvail50PercentDiscount = 2e6;
    uint256 public constant numberOfTokensToAvail25percentDiscount = 5e5;
    uint256 public constant minimumNumberOfTokens = 2500;
    uint256 public targetToAchieve;

    bool public inventoryLocked = false;
    uint256 public totalSupply;
     
    uint256 public totalSupplyForCrowdsaleAndMint = 0;
     
    address public coinbase;
     
    uint256 public ETHReceived;
     
    uint256 public totalSupplyFromInventory;
     
    uint256 public totalRemainInInventory;
     
    uint256 public getPrice;
     
     
     
     
    uint256 public crowdsaleStatus;
     
     
     
    uint8 public crowdSaleType;
     
    event ReceivedETH(address addr, uint value);
     
    event MintAndTransferIAC(address addr, uint value, bytes32 comment);
     
    event SuccessfullyTransferedFromCompanyInventory(address addr, uint value, bytes32 comment);
     
    event TokenSupplied(address indexed beneficiary, uint256 indexed tokens, uint256 value);
     
    event StateChanged(bool changed);

     
    Metadata private objMetada;
    Ecosystem private objEcosystem;
    CompanyInventory private objCompanyInventory;
    address private ecosystemContractAddress;
     
    uint256 constant ecosystemContractID = 1;
     
    uint256 constant private crowdsaleContractID = 2;
     
    uint256 constant private inventoryContractID = 3;

     
    function Crowdsale() public {
        address _metadataContractAddr = 0x8A8473E51D7f562ea773A019d7351A96c419B633;
        startBlock = 0;
        endBlock = 0;
        crowdSaleType = 1;
        totalSupply = maxCapEcosystem;
        crowdsaleStatus=0;
        coinbase = 0xA84196972d6b5796cE523f861CC9E367F739421F;
        owner = msg.sender;
        totalSupplyFromInventory=0;
        totalRemainInInventory = maxCapCompanyInventory;
        getPrice = 2778;
        objMetada = Metadata(_metadataContractAddr);
        ecosystemContractAddress = objMetada.getAddress(ecosystemContractID);
        assert(ecosystemContractAddress != address(0));
        objEcosystem = Ecosystem(ecosystemContractAddress);
        objMetada.addAddress(crowdsaleContractID, this);
        balances[ecosystemContractAddress] = maxCapEcosystem;
        targetToAchieve = (50000*100e18)/(12*getPrice);
    }

     
    modifier onlyOwner() {
      require(msg.sender == owner);
      _;
    }

     
    modifier respectTimeFrame() {
       
      assert(startBlock != 0 && !stopped && crowdsaleStatus == 1);
       
      if(now > endBlock){
           
          revert();
      }
      _;
    }

     
    function SetEcosystemContract () public onlyOwner {
        uint256 balanceOfOldEcosystem = balances[ecosystemContractAddress];
        balances[ecosystemContractAddress] = 0;
         
        ecosystemContractAddress = objMetada.getAddress(ecosystemContractID);
         
        balances[ecosystemContractAddress] = balanceOfOldEcosystem;
        assert(ecosystemContractAddress != address(0));
        objEcosystem = Ecosystem(ecosystemContractAddress);
    }

    function GetIACFundAccount() internal view returns (address) {
        uint remainder = block.number%10;
        if(remainder==0){
            return 0x8786DB52D292551f4139a963F79Ce1018d909655;
        } else if(remainder==1){
            return 0x11818E22CDc0592F69a22b30CF0182888f315FBC;
        } else if(remainder==2){
            return 0x17616b652C3c2eAf2aa82a72Bd2b3cFf40A854fE;
        } else if(remainder==3){
            return 0xD433632CA5cAFDa27655b8E536E5c6335343d408;
        } else if(remainder==4){
            return 0xb0Dc59A8312D901C250f8975E4d99eAB74D79484;
        } else if(remainder==5){
            return 0x0e6B1F7955EF525C2707799963318c49f9Ad7374;
        } else if(remainder==6){
            return 0x2fE6C4D2DC0EB71d2ac885F64f029CE78b9F98d9;
        } else if(remainder==7){
            return 0x0a7cD1cCc55191F8046D1023340bdfdfa475F267;
        } else if(remainder==8){
            return 0x76C40fDFd3284da796851611e7e9e8De0CcA546C;
        }else {
            return 0xe4FE5295772997272914447549D570882423A227;
        }
  }
     
    function startSale() public onlyOwner {
        assert(startBlock == 0);
         
        startBlock = now;
         
        crowdSaleType = 1;
         
        crowdsaleStatus = 1;
         
        endBlock = now.Add(durationCrowdSale);
         
        StateChanged(true);
    }

     
    function startSecondaryCrowdsale (uint256 durationSecondaryCrowdSale) public onlyOwner {
       
       
       
      assert(crowdsaleStatus == 2 && crowdSaleType == 1);
      if(now > endBlock.Add(gapInPrimaryCrowdsaleAndSecondaryCrowdsale)){
           
          crowdsaleStatus = 1;
           
          crowdSaleType = 2;
           
          endBlock = now.Add(durationSecondaryCrowdSale * 86400);
           
          StateChanged(true);
      }
      else
        revert();
    }
    

     
    function setPrice(uint _tokensPerEther) public onlyOwner
    {
        require( _tokensPerEther != 0);
        getPrice = _tokensPerEther;
        targetToAchieve = (50000*100e18)/(12*_tokensPerEther);
         
        StateChanged(true);
    }

     
    function createTokens(address beneficiary) internal stopInEmergency  respectTimeFrame {
         
        require(msg.value != 0);
         
        uint256 iacToSend = (msg.value.Mul(getPrice))/1e18;
         
        uint256 priceToAvail50PercentDiscount = numberOfTokensToAvail50PercentDiscount.Div(2*getPrice).Mul(1e18);
         
        uint256 priceToAvail25PercentDiscount = 3*numberOfTokensToAvail25percentDiscount.Div(4*getPrice).Mul(1e18);
         
        if(iacToSend < minimumNumberOfTokens){
            revert();
        }
        else if(msg.value >= priceToAvail25PercentDiscount && msg.value < priceToAvail50PercentDiscount){
             
            iacToSend = (((msg.value.Mul(getPrice)).Mul(4)).Div(3))/1e18;
        }
         
        else if(msg.value >= priceToAvail50PercentDiscount){
             
            iacToSend = (msg.value.Mul(2*getPrice))/1e18;
        }
         
        else {
            iacToSend = (msg.value.Mul(getPrice))/1e18;
        }
         
        assert(iacToSend.Add(totalSupplyForCrowdsaleAndMint) <= maxCap);
         
        totalSupply = totalSupply.Add(iacToSend);

        totalSupplyForCrowdsaleAndMint = totalSupplyForCrowdsaleAndMint.Add(iacToSend);

        if(ETHReceived < targetToAchieve){
             
            coinbase.transfer(msg.value);
        }
        else{
            GetIACFundAccount().transfer(msg.value);
        }

         
        ETHReceived = ETHReceived.Add(msg.value);
         
        ReceivedETH(beneficiary,ETHReceived);
        balances[beneficiary] = balances[beneficiary].Add(iacToSend);

        TokenSupplied(beneficiary, iacToSend, msg.value);
         
        StateChanged(true);
    }

     
    function MintAndTransferToken(address beneficiary,uint256 iacToCredit,bytes32 comment) external onlyOwner {
         
        assert(crowdsaleStatus == 1 && beneficiary != address(0));
         
        require(iacToCredit >= 1);
         
        assert(totalSupplyForCrowdsaleAndMint <= maxCap);
         
        require(totalSupplyForCrowdsaleAndMint.Add(iacToCredit) <= maxCap);
         
        balances[beneficiary] = balances[beneficiary].Add(iacToCredit);
         
        totalSupply = totalSupply.Add(iacToCredit);
        totalSupplyForCrowdsaleAndMint = totalSupplyForCrowdsaleAndMint.Add(iacToCredit);
         
        MintAndTransferIAC(beneficiary, iacToCredit, comment);
         
        StateChanged(true);
    }

     
    function TransferFromCompanyInventory(address beneficiary,uint256 iacToCredit,bytes32 comment) external onlyOwner {
         
        assert(startBlock != 0 && beneficiary != address(0));
         
        assert(totalSupplyFromInventory <= maxCapCompanyInventory && !inventoryLocked);
         
        require(iacToCredit >= 1);
         
        require(totalSupplyFromInventory.Add(iacToCredit) <= maxCapCompanyInventory);
         
        balances[beneficiary] = balances[beneficiary].Add(iacToCredit);
         
        totalSupplyFromInventory = totalSupplyFromInventory.Add(iacToCredit);
         
        totalSupply = totalSupply.Add(iacToCredit);
         
        totalRemainInInventory = totalRemainInInventory.Sub(iacToCredit);
         
        SuccessfullyTransferedFromCompanyInventory(beneficiary, iacToCredit, comment);
         
        StateChanged(true);
    }

    function LockInventory () public onlyOwner {
        require(startBlock > 0 && now >= startBlock.Add(durationCrowdSale.Add(90 days)) && !inventoryLocked);
        address inventoryContractAddress = objMetada.getAddress(inventoryContractID);
        require(inventoryContractAddress != address(0));
        balances[inventoryContractAddress] = totalRemainInInventory;
        totalSupply = totalSupply.Add(totalRemainInInventory);
        objCompanyInventory = CompanyInventory(inventoryContractAddress);
        objCompanyInventory.initiateLocking(totalSupplyFromInventory);
        inventoryLocked = true;
    }

     
    function finalize() public onlyOwner {
           
           
          assert(crowdsaleStatus == 1 && (crowdSaleType == 1 || crowdSaleType == 2));
           
          assert(maxCap.Sub(totalSupplyForCrowdsaleAndMint) < minimumNumberOfTokens || now >= endBlock);
           
          crowdsaleStatus = 2;
           
          endBlock = now;
           
          StateChanged(true);
    }

     
    function unlock() public onlyOwner
    {
         
         
        assert(crowdsaleStatus==2 && now >= startBlock.Add(durationCrowdSale.Add(90 days)));
        locked = false;
         
        StateChanged(true);
    }

     
    function () public payable {
        createTokens(msg.sender);
    }

    
   function drain() public  onlyOwner {
        GetIACFundAccount().transfer(this.balance);
  }
}