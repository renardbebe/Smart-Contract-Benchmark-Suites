 

pragma solidity ^0.4.18;


contract GroupBuyContract {
   
  uint256 public constant MAX_CONTRIBUTION_SLOTS = 20;
  uint256 private firstStepLimit =  0.053613 ether;
  uint256 private secondStepLimit = 0.564957 ether;

   
   
   
  struct Group {
     
    address[] contributorArr;
     
     
    mapping(address => uint256) addressToContributorArrIndex;
    mapping(address => uint256) addressToContribution;  
    bool exists;  
    uint256 contributedBalance;  
    uint256 purchasePrice;  
  }

   
   
   
  struct Contributor {
     
     
    mapping(uint256 => uint) tokenIdToGroupArrIndex;
     
    uint256[] groupArr;
    bool exists;
     
     
     
     
    uint256 withdrawableBalance;
  }

   
   
   
  event Commission(uint256 _tokenId, uint256 amount);

   
   
  event FundsReceived(address _from, uint256 amount);

   
   
  event FundsDeposited(address _to, uint256 amount);

   
  event FundsWithdrawn(address _to, uint256 amount);

   
   
  event InterestDeposited(uint256 _tokenId, address _to, uint256 amount);

   
  event JoinGroup(
    uint256 _tokenId,
    address contributor,
    uint256 groupBalance,
    uint256 contributionAdded
  );

   
  event LeaveGroup(
    uint256 _tokenId,
    address contributor,
    uint256 groupBalance,
    uint256 contributionSubtracted
  );

   
  event ProceedsDeposited(uint256 _tokenId, address _to, uint256 amount);

   
  event TokenPurchased(uint256 _tokenId, uint256 balance);

   
   
  address public ceoAddress;
  address public cfoAddress;
  address public cooAddress1;
  address public cooAddress2;
  address public cooAddress3;

   
  bool public paused = false;
  bool public forking = false;

  uint256 public activeGroups;
  uint256 public commissionBalance;
  uint256 private distributionNumerator;
  uint256 private distributionDenominator;

  CelebrityToken public linkedContract;

   
  mapping(uint256 => Group) private tokenIndexToGroup;

   
  mapping(address => Contributor) private userAddressToContributor;

   
   
  modifier onlyCEO() {
    require(msg.sender == ceoAddress);
    _;
  }

   
  modifier onlyCFO() {
    require(msg.sender == cfoAddress);
    _;
  }

   
  modifier onlyCOO() {
    require(
      msg.sender == cooAddress1 ||
      msg.sender == cooAddress2 ||
      msg.sender == cooAddress3
    );
    _;
  }

   
  modifier onlyCLevel() {
    require(
      msg.sender == ceoAddress ||
      msg.sender == cooAddress1 ||
      msg.sender == cooAddress2 ||
      msg.sender == cooAddress3 ||
      msg.sender == cfoAddress
    );
    _;
  }

   
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

   
  modifier whenPaused {
    require(paused);
    _;
  }

   
  modifier whenNotForking() {
    require(!forking);
    _;
  }

   
  modifier whenForking {
    require(forking);
    _;
  }

   
  function GroupBuyContract(address contractAddress, uint256 numerator, uint256 denominator) public {
    ceoAddress = msg.sender;
    cooAddress1 = msg.sender;
    cooAddress2 = msg.sender;
    cooAddress3 = msg.sender;
    cfoAddress = msg.sender;
    distributionNumerator = numerator;
    distributionDenominator = denominator;
    linkedContract = CelebrityToken(contractAddress);
  }

   
   
  function() external payable {
    FundsReceived(msg.sender, msg.value);
  }

   
   
   
   
  function activatePurchase(uint256 _tokenId) external whenNotPaused {
    var group = tokenIndexToGroup[_tokenId];
    require(group.addressToContribution[msg.sender] > 0 ||
            msg.sender == ceoAddress ||
            msg.sender == cooAddress1 ||
            msg.sender == cooAddress2 ||
            msg.sender == cooAddress3 ||
            msg.sender == cfoAddress);

     
    var price = linkedContract.priceOf(_tokenId);
    require(group.contributedBalance >= price);

     
    require(group.purchasePrice == 0);

    _purchase(_tokenId, price);
  }

   
   
  function contributeToTokenGroup(uint256 _tokenId)
  external payable whenNotForking whenNotPaused {
    address userAdd = msg.sender;
     
    require(_addressNotNull(userAdd));

     
    var group = tokenIndexToGroup[_tokenId];
    var contributor = userAddressToContributor[userAdd];
    if (!group.exists) {  
      group.exists = true;
      activeGroups += 1;
    } else {
      require(group.addressToContributorArrIndex[userAdd] == 0);
    }

    if (!contributor.exists) {  
      userAddressToContributor[userAdd].exists = true;
    } else {
      require(contributor.tokenIdToGroupArrIndex[_tokenId] == 0);
    }

     
     
    require(group.purchasePrice == 0);

     
     
    uint256 tokenPrice = linkedContract.priceOf(_tokenId);
    require(msg.value >= uint256(SafeMath.div(tokenPrice, MAX_CONTRIBUTION_SLOTS)));

     
     
    uint256 cIndex = tokenIndexToGroup[_tokenId].contributorArr.push(userAdd);
    tokenIndexToGroup[_tokenId].addressToContributorArrIndex[userAdd] = cIndex;

    uint256 amountNeeded = SafeMath.sub(tokenPrice, group.contributedBalance);
    if (msg.value > amountNeeded) {
      tokenIndexToGroup[_tokenId].addressToContribution[userAdd] = amountNeeded;
      tokenIndexToGroup[_tokenId].contributedBalance += amountNeeded;
       
      userAddressToContributor[userAdd].withdrawableBalance += SafeMath.sub(msg.value, amountNeeded);
      FundsDeposited(userAdd, SafeMath.sub(msg.value, amountNeeded));
    } else {
      tokenIndexToGroup[_tokenId].addressToContribution[userAdd] = msg.value;
      tokenIndexToGroup[_tokenId].contributedBalance += msg.value;
    }

     
     
    uint256 gIndex = userAddressToContributor[userAdd].groupArr.push(_tokenId);
    userAddressToContributor[userAdd].tokenIdToGroupArrIndex[_tokenId] = gIndex;

    JoinGroup(
      _tokenId,
      userAdd,
      tokenIndexToGroup[_tokenId].contributedBalance,
      tokenIndexToGroup[_tokenId].addressToContribution[userAdd]
    );

     
    if (tokenIndexToGroup[_tokenId].contributedBalance >= tokenPrice) {
      _purchase(_tokenId, tokenPrice);
    }
  }

   
   
   
   
  function leaveTokenGroup(uint256 _tokenId) external whenNotPaused {
    address userAdd = msg.sender;

    var group = tokenIndexToGroup[_tokenId];
    var contributor = userAddressToContributor[userAdd];

     
    require(_addressNotNull(userAdd));

     
    require(group.exists);

     
    require(group.purchasePrice == 0);

     
    require(group.addressToContributorArrIndex[userAdd] > 0);
    require(contributor.tokenIdToGroupArrIndex[_tokenId] > 0);

    uint refundBalance = _clearContributorRecordInGroup(_tokenId, userAdd);
    _clearGroupRecordInContributor(_tokenId, userAdd);

    userAddressToContributor[userAdd].withdrawableBalance += refundBalance;
    FundsDeposited(userAdd, refundBalance);

    LeaveGroup(
      _tokenId,
      userAdd,
      tokenIndexToGroup[_tokenId].contributedBalance,
      refundBalance
    );
  }

   
   
   
  function leaveTokenGroupAndWithdrawBalance(uint256 _tokenId) external whenNotPaused {
    address userAdd = msg.sender;

    var group = tokenIndexToGroup[_tokenId];
    var contributor = userAddressToContributor[userAdd];

     
    require(_addressNotNull(userAdd));

     
    require(group.exists);

     
    require(group.purchasePrice == 0);

     
    require(group.addressToContributorArrIndex[userAdd] > 0);
    require(contributor.tokenIdToGroupArrIndex[_tokenId] > 0);

    uint refundBalance = _clearContributorRecordInGroup(_tokenId, userAdd);
    _clearGroupRecordInContributor(_tokenId, userAdd);

    userAddressToContributor[userAdd].withdrawableBalance += refundBalance;
    FundsDeposited(userAdd, refundBalance);

    _withdrawUserFunds(userAdd);

    LeaveGroup(
      _tokenId,
      userAdd,
      tokenIndexToGroup[_tokenId].contributedBalance,
      refundBalance
    );
  }

   
  function withdrawBalance() external whenNotPaused {
    require(_addressNotNull(msg.sender));
    require(userAddressToContributor[msg.sender].exists);

    _withdrawUserFunds(msg.sender);
  }

   
   
   
   
  function adjustCommission(uint256 numerator, uint256 denominator) external onlyCLevel {
    require(numerator <= denominator);
    distributionNumerator = numerator;
    distributionDenominator = denominator;
  }

   
   
   
   
  function dissolveTokenGroup(uint256 _tokenId) external onlyCOO whenForking {
    var group = tokenIndexToGroup[_tokenId];

     
    require(group.exists);
    require(group.purchasePrice == 0);

    for (uint i = 0; i < tokenIndexToGroup[_tokenId].contributorArr.length; i++) {
      address userAdd = tokenIndexToGroup[_tokenId].contributorArr[i];

      var userContribution = group.addressToContribution[userAdd];

      _clearGroupRecordInContributor(_tokenId, userAdd);

       
      tokenIndexToGroup[_tokenId].addressToContribution[userAdd] = 0;
      tokenIndexToGroup[_tokenId].addressToContributorArrIndex[userAdd] = 0;

       
      userAddressToContributor[userAdd].withdrawableBalance += userContribution;
      ProceedsDeposited(_tokenId, userAdd, userContribution);
    }
    activeGroups -= 1;
    tokenIndexToGroup[_tokenId].exists = false;
  }

   
   
   
   
   
  function distributeCustomSaleProceeds(uint256 _tokenId, uint256 _amount) external onlyCOO {
    var group = tokenIndexToGroup[_tokenId];

     
    require(group.exists);
    require(group.purchasePrice > 0);
    require(_amount > 0);

    _distributeProceeds(_tokenId, _amount);
  }

   

   
   
   
  function distributeSaleProceeds(uint256 _tokenId) external onlyCOO {
    var group = tokenIndexToGroup[_tokenId];

     
    require(group.exists);
    require(group.purchasePrice > 0);

     
    uint256 currPrice = linkedContract.priceOf(_tokenId);
    uint256 soldPrice = _newPrice(group.purchasePrice);
    require(currPrice > soldPrice);

    uint256 paymentIntoContract = uint256(SafeMath.div(SafeMath.mul(soldPrice, 94), 100));
    _distributeProceeds(_tokenId, paymentIntoContract);
  }

   
   
  function pause() external onlyCLevel whenNotPaused {
    paused = true;
  }

   
   
   
  function unpause() external onlyCEO whenPaused {
     
    paused = false;
  }

   
   
  function setToForking() external onlyCLevel whenNotForking {
    forking = true;
  }

   
   
   
  function setToNotForking() external onlyCEO whenForking {
     
    forking = false;
  }

   
   
  function setCEO(address _newCEO) external onlyCEO {
    require(_newCEO != address(0));

    ceoAddress = _newCEO;
  }

   
   
  function setCFO(address _newCFO) external onlyCEO {
    require(_newCFO != address(0));

    cfoAddress = _newCFO;
  }

   
   
  function setCOO1(address _newCOO1) external onlyCEO {
    require(_newCOO1 != address(0));

    cooAddress1 = _newCOO1;
  }

   
   
  function setCOO2(address _newCOO2) external onlyCEO {
    require(_newCOO2 != address(0));

    cooAddress2 = _newCOO2;
  }

   
   
  function setCOO3(address _newCOO3) external onlyCEO {
    require(_newCOO3 != address(0));

    cooAddress3 = _newCOO3;
  }

   
   
   
   
   
  function transferToken(uint256 _tokenId, address _to) external onlyCOO {
    var group = tokenIndexToGroup[_tokenId];

     
    require(group.exists);
    require(group.purchasePrice > 0);

    linkedContract.transfer(_to, _tokenId);
  }

   
   
  function withdrawCommission(address _to) external onlyCFO {
    uint256 balance = commissionBalance;
    address transferee = (_to == address(0)) ? cfoAddress : _to;
    commissionBalance = 0;
    if (balance > 0) {
      transferee.transfer(balance);
    }
    FundsWithdrawn(transferee, balance);
  }

   
   
   
  function getContributionBalanceForTokenGroup(uint256 _tokenId, address userAdd) external view returns (uint balance) {
    var group = tokenIndexToGroup[_tokenId];
    require(group.exists);
    balance = group.addressToContribution[userAdd];
  }

   
   
  function getSelfContributionBalanceForTokenGroup(uint256 _tokenId) external view returns (uint balance) {
    var group = tokenIndexToGroup[_tokenId];
    require(group.exists);
    balance = group.addressToContribution[msg.sender];
  }

   
   
  function getContributorsInTokenGroup(uint256 _tokenId) external view returns (address[] contribAddr) {
    var group = tokenIndexToGroup[_tokenId];
    require(group.exists);
    contribAddr = group.contributorArr;
  }

   
   
  function getContributorsInTokenGroupCount(uint256 _tokenId) external view returns (uint count) {
    var group = tokenIndexToGroup[_tokenId];
    require(group.exists);
    count = group.contributorArr.length;
  }

   
  function getGroupsContributedTo(address userAdd) external view returns (uint256[] groupIds) {
     
    require(_addressNotNull(userAdd));

    var contributor = userAddressToContributor[userAdd];
    require(contributor.exists);

    groupIds = contributor.groupArr;
  }

   
  function getSelfGroupsContributedTo() external view returns (uint256[] groupIds) {
     
    require(_addressNotNull(msg.sender));

    var contributor = userAddressToContributor[msg.sender];
    require(contributor.exists);

    groupIds = contributor.groupArr;
  }

   
  function getGroupPurchasedPrice(uint256 _tokenId) external view returns (uint256 price) {
    var group = tokenIndexToGroup[_tokenId];
    require(group.exists);
    require(group.purchasePrice > 0);
    price = group.purchasePrice;
  }

   
  function getWithdrawableBalance() external view returns (uint256 balance) {
     
    require(_addressNotNull(msg.sender));

    var contributor = userAddressToContributor[msg.sender];
    require(contributor.exists);

    balance = contributor.withdrawableBalance;
  }

   
   
  function getTokenGroupTotalBalance(uint256 _tokenId) external view returns (uint balance) {
    var group = tokenIndexToGroup[_tokenId];
    require(group.exists);
    balance = group.contributedBalance;
  }

   
   
   
  function _addressNotNull(address _to) private pure returns (bool) {
    return _to != address(0);
  }

   
   
   
  function _clearContributorRecordInGroup(uint256 _tokenId, address _userAdd) private returns (uint256 refundBalance) {
    var group = tokenIndexToGroup[_tokenId];

     
     
    uint cIndex = group.addressToContributorArrIndex[_userAdd] - 1;
    uint lastCIndex = group.contributorArr.length - 1;
    refundBalance = group.addressToContribution[_userAdd];

     
    tokenIndexToGroup[_tokenId].addressToContributorArrIndex[_userAdd] = 0;
    tokenIndexToGroup[_tokenId].addressToContribution[_userAdd] = 0;

     
    if (lastCIndex > 0) {
      tokenIndexToGroup[_tokenId].addressToContributorArrIndex[group.contributorArr[lastCIndex]] = cIndex;
      tokenIndexToGroup[_tokenId].contributorArr[cIndex] = group.contributorArr[lastCIndex];
    }

    tokenIndexToGroup[_tokenId].contributorArr.length -= 1;
    tokenIndexToGroup[_tokenId].contributedBalance -= refundBalance;
  }

   
   
   
  function _clearGroupRecordInContributor(uint256 _tokenId, address _userAdd) private {
     
     
    uint gIndex = userAddressToContributor[_userAdd].tokenIdToGroupArrIndex[_tokenId] - 1;
    uint lastGIndex = userAddressToContributor[_userAdd].groupArr.length - 1;

     
    userAddressToContributor[_userAdd].tokenIdToGroupArrIndex[_tokenId] = 0;

     
    if (lastGIndex > 0) {
      userAddressToContributor[_userAdd].tokenIdToGroupArrIndex[userAddressToContributor[_userAdd].groupArr[lastGIndex]] = gIndex;
      userAddressToContributor[_userAdd].groupArr[gIndex] = userAddressToContributor[_userAdd].groupArr[lastGIndex];
    }

    userAddressToContributor[_userAdd].groupArr.length -= 1;
  }

   
   
   
  function _distributeProceeds(uint256 _tokenId, uint256 _amount) private {
    uint256 fundsForDistribution = uint256(SafeMath.div(SafeMath.mul(_amount,
      distributionNumerator), distributionDenominator));
    uint256 commission = _amount;

    for (uint i = 0; i < tokenIndexToGroup[_tokenId].contributorArr.length; i++) {
      address userAdd = tokenIndexToGroup[_tokenId].contributorArr[i];

       
      uint256 userProceeds = uint256(SafeMath.div(SafeMath.mul(fundsForDistribution,
        tokenIndexToGroup[_tokenId].addressToContribution[userAdd]),
        tokenIndexToGroup[_tokenId].contributedBalance));

      _clearGroupRecordInContributor(_tokenId, userAdd);

       
      tokenIndexToGroup[_tokenId].addressToContribution[userAdd] = 0;
      tokenIndexToGroup[_tokenId].addressToContributorArrIndex[userAdd] = 0;

      commission -= userProceeds;
      userAddressToContributor[userAdd].withdrawableBalance += userProceeds;
      ProceedsDeposited(_tokenId, userAdd, userProceeds);
    }

    commissionBalance += commission;
    Commission(_tokenId, commission);

    activeGroups -= 1;
    tokenIndexToGroup[_tokenId].exists = false;
    tokenIndexToGroup[_tokenId].contributorArr.length = 0;
    tokenIndexToGroup[_tokenId].contributedBalance = 0;
    tokenIndexToGroup[_tokenId].purchasePrice = 0;
  }

   
   
  function _newPrice(uint256 _oldPrice) private view returns (uint256 newPrice) {
    if (_oldPrice < firstStepLimit) {
       
      newPrice = SafeMath.div(SafeMath.mul(_oldPrice, 200), 94);
    } else if (_oldPrice < secondStepLimit) {
       
      newPrice = SafeMath.div(SafeMath.mul(_oldPrice, 120), 94);
    } else {
       
      newPrice = SafeMath.div(SafeMath.mul(_oldPrice, 115), 94);
    }
  }

   
   
   
  function _purchase(uint256 _tokenId, uint256 _amount) private {
    tokenIndexToGroup[_tokenId].purchasePrice = _amount;
    linkedContract.purchase.value(_amount)(_tokenId);
    TokenPurchased(_tokenId, _amount);
  }

  function _withdrawUserFunds(address userAdd) private {
    uint256 balance = userAddressToContributor[userAdd].withdrawableBalance;
    userAddressToContributor[userAdd].withdrawableBalance = 0;

    if (balance > 0) {
      FundsWithdrawn(userAdd, balance);
      userAdd.transfer(balance);
    }
  }
}


 
 
contract ERC721 {
   
  function approve(address _to, uint256 _tokenId) public;
  function balanceOf(address _owner) public view returns (uint256 balance);
  function implementsERC721() public pure returns (bool);
  function ownerOf(uint256 _tokenId) public view returns (address addr);
  function takeOwnership(uint256 _tokenId) public;
  function totalSupply() public view returns (uint256 total);
  function transferFrom(address _from, address _to, uint256 _tokenId) public;
  function transfer(address _to, uint256 _tokenId) public;

  event Transfer(address indexed from, address indexed to, uint256 tokenId);
  event Approval(address indexed owner, address indexed approved, uint256 tokenId);

   
   
   
   
   
}


contract CelebrityToken is ERC721 {

   

   
  event Birth(uint256 tokenId, string name, address owner);

   
  event TokenSold(uint256 tokenId, uint256 oldPrice, uint256 newPrice, address prevOwner, address winner, string name);

   
   
  event Transfer(address from, address to, uint256 tokenId);

   

   
  string public constant NAME = "CryptoCelebrities";  
  string public constant SYMBOL = "CelebrityToken";  

  address public ceoAddress;
  address public cooAddress;

  uint256 public promoCreatedCount;

   
  struct Person {
    string name;
  }

   
  function CelebrityToken() public {
    ceoAddress = msg.sender;
    cooAddress = msg.sender;
  }

   
   
   
   
   
   
  function approve(
    address _to,
    uint256 _tokenId
  ) public;

   
   
   
  function balanceOf(address _owner) public view returns (uint256 balance);

   
  function createPromoPerson(address _owner, string _name, uint256 _price) public;

   
  function createContractPerson(string _name) public;

   
   
  function getPerson(uint256 _tokenId) public view returns (
    string personName,
    uint256 sellingPrice,
    address owner
  );

  function implementsERC721() public pure returns (bool);

   
  function name() public pure returns (string);

   
   
   
  function ownerOf(uint256 _tokenId)
    public
    view
    returns (address owner);
    
  function payout(address _to) public;

   
  function purchase(uint256 _tokenId) public payable;

  function priceOf(uint256 _tokenId) public view returns (uint256 price);
   
   
  function setCEO(address _newCEO) public;

   
   
  function setCOO(address _newCOO) public;

   
  function symbol() public pure returns (string);
   
   
   
  function takeOwnership(uint256 _tokenId) public;

   
   
   
   
   
  function tokensOfOwner(address _owner) public view returns(uint256[] ownerTokens);

   
   
  function totalSupply() public view returns (uint256 total);

   
   
   
   
  function transfer(
    address _to,
    uint256 _tokenId
  ) public;

   
   
   
   
   
  function transferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  ) public;

   
   
  function _addressNotNull(address _to) private pure returns (bool);

   
  function _approved(address _to, uint256 _tokenId) private view returns (bool);

   
  function _createPerson(string _name, address _owner, uint256 _price) private;

   
  function _owns(address claimant, uint256 _tokenId) private view returns (bool);

   
  function _payout(address _to) private;

   
  function _transfer(address _from, address _to, uint256 _tokenId) private;
}


library SafeMath {
   
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}