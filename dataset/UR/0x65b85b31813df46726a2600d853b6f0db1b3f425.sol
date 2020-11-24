 

pragma solidity 0.4.24;
 
 
 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  function Ownable() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

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

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

   
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

     
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

}

contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


   
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

   
  modifier whenPaused() {
    require(paused);
    _;
  }

   
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    Pause();
  }

   
  function unpause() onlyOwner whenPaused public {
    paused = false;
    Unpause();
  }
}

contract Relay is Ownable {
    address public licenseSalesContractAddress;
    address public registryContractAddress;
    address public apiRegistryContractAddress;
    address public apiCallsContractAddress;
    uint public version;

     
     
     
    constructor() public {
        version = 4;
    }

     
     
     
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20(tokenAddress).transfer(owner, tokens);
    }

     
     
     
    function setLicenseSalesContractAddress(address newAddress) public onlyOwner {
        require(newAddress != address(0));
        licenseSalesContractAddress = newAddress;
    }

     
     
     
    function setRegistryContractAddress(address newAddress) public onlyOwner {
        require(newAddress != address(0));
        registryContractAddress = newAddress;
    }

     
     
     
    function setApiRegistryContractAddress(address newAddress) public onlyOwner {
        require(newAddress != address(0));
        apiRegistryContractAddress = newAddress;
    }

     
     
     
    function setApiCallsContractAddress(address newAddress) public onlyOwner {
        require(newAddress != address(0));
        apiCallsContractAddress = newAddress;
    }
}
contract APIRegistry is Ownable {

    struct APIForSale {
        uint pricePerCall;
        bytes32 sellerUsername;
        bytes32 apiName;
        address sellerAddress;
        string hostname;
        string docsUrl;
    }

    mapping(string => uint) internal apiIds;
    mapping(uint => APIForSale) public apis;

    uint public numApis;
    uint public version;

     
     
     
    constructor() public {
        numApis = 0;
        version = 1;
    }

     
     
     
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20(tokenAddress).transfer(owner, tokens);
    }

     
     
     
    function listApi(uint pricePerCall, bytes32 sellerUsername, bytes32 apiName, string hostname, string docsUrl) public {
         
        require(pricePerCall != 0 && sellerUsername != "" && apiName != "" && bytes(hostname).length != 0);
        
         
        require(apiIds[hostname] == 0);

        numApis += 1;
        apiIds[hostname] = numApis;

        APIForSale storage api = apis[numApis];

        api.pricePerCall = pricePerCall;
        api.sellerUsername = sellerUsername;
        api.apiName = apiName;
        api.sellerAddress = msg.sender;
        api.hostname = hostname;
        api.docsUrl = docsUrl;
    }

     
     
     
    function getApiId(string hostname) public view returns (uint) {
        return apiIds[hostname];
    }

     
     
     
    function getApiByIdWithoutDynamics(
        uint apiId
    ) 
        public
        view 
        returns (
            uint pricePerCall, 
            bytes32 sellerUsername,
            bytes32 apiName, 
            address sellerAddress
        ) 
    {
        APIForSale storage api = apis[apiId];

        pricePerCall = api.pricePerCall;
        sellerUsername = api.sellerUsername;
        apiName = api.apiName;
        sellerAddress = api.sellerAddress;
    }

     
     
     
    function getApiById(
        uint apiId
    ) 
        public 
        view 
        returns (
            uint pricePerCall, 
            bytes32 sellerUsername, 
            bytes32 apiName, 
            address sellerAddress, 
            string hostname, 
            string docsUrl
        ) 
    {
        APIForSale storage api = apis[apiId];

        pricePerCall = api.pricePerCall;
        sellerUsername = api.sellerUsername;
        apiName = api.apiName;
        sellerAddress = api.sellerAddress;
        hostname = api.hostname;
        docsUrl = api.docsUrl;
    }

     
     
     
    function getApiByName(
        string _hostname
    ) 
        public 
        view 
        returns (
            uint pricePerCall, 
            bytes32 sellerUsername, 
            bytes32 apiName, 
            address sellerAddress, 
            string hostname, 
            string docsUrl
        ) 
    {
        uint apiId = apiIds[_hostname];
        if (apiId == 0) {
            return;
        }
        APIForSale storage api = apis[apiId];

        pricePerCall = api.pricePerCall;
        sellerUsername = api.sellerUsername;
        apiName = api.apiName;
        sellerAddress = api.sellerAddress;
        hostname = api.hostname;
        docsUrl = api.docsUrl;
    }

     
     
     
    function editApi(uint apiId, uint pricePerCall, address sellerAddress, string docsUrl) public {
        require(apiId != 0 && pricePerCall != 0 && sellerAddress != address(0));

        APIForSale storage api = apis[apiId];

         
        require(
            api.pricePerCall != 0 && api.sellerUsername != "" && api.apiName != "" &&  bytes(api.hostname).length != 0 && api.sellerAddress != address(0)
        );

         
         
        require(msg.sender == api.sellerAddress || msg.sender == owner);

        api.pricePerCall = pricePerCall;
        api.sellerAddress = sellerAddress;
        api.docsUrl = docsUrl;
    }
}
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

contract DeconetToken is StandardToken, Ownable, Pausable {
     
    string public constant symbol = "DCO";
    string public constant name = "Deconet Token";
    uint8 public constant decimals = 18;

     
    uint public constant version = 4;

     
     
     
    constructor() public {
         
        totalSupply_ = 1000000000 * 10**uint(decimals);

         
        balances[msg.sender] = totalSupply_;
        Transfer(address(0), msg.sender, totalSupply_);

         
        paused = true;
    }

     
     
     
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20(tokenAddress).transfer(owner, tokens);
    }

     
     
     
     
    modifier whenOwnerOrNotPaused() {
        require(msg.sender == owner || !paused);
        _;
    }

     
     
     
    function transfer(address _to, uint256 _value) public whenOwnerOrNotPaused returns (bool) {
        return super.transfer(_to, _value);
    }

     
     
     
    function transferFrom(address _from, address _to, uint256 _value) public whenOwnerOrNotPaused returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }

     
     
     
    function approve(address _spender, uint256 _value) public whenOwnerOrNotPaused returns (bool) {
        return super.approve(_spender, _value);
    }

     
     
     
    function increaseApproval(address _spender, uint _addedValue) public whenOwnerOrNotPaused returns (bool success) {
        return super.increaseApproval(_spender, _addedValue);
    }

     
     
     
    function decreaseApproval(address _spender, uint _subtractedValue) public whenOwnerOrNotPaused returns (bool success) {
        return super.decreaseApproval(_spender, _subtractedValue);
    }
}

contract APICalls is Ownable {
    using SafeMath for uint;

     
    uint public tokenReward;

     
    uint public saleFee;

     
     
    uint public defaultBuyerLastPaidAt;

     
    address public relayContractAddress;

     
    address public tokenContractAddress;

     
    uint public version;

     
    uint public safeWithdrawAmount;

     
    address private withdrawAddress;

     
    address private usageReportingAddress;

     
    mapping(uint => APIBalance) internal owed;

     
    mapping(address => BuyerInfo) internal buyers;

     
    struct APIBalance {
         
        mapping(address => uint) amounts;
         
        address[] nonzeroAddresses;
         
        mapping(address => uint) buyerLastPaidAt;
    }

     
    struct BuyerInfo {
         
        bool overdrafted;
         
        uint lifetimeOverdraftCount;
         
        uint credits;
         
        uint lifetimeCreditsUsed;
         
        mapping(uint => uint) approvedAmounts;
         
        mapping(uint => bool) exceededApprovedAmount;
         
        uint lifetimeExceededApprovalAmountCount;
    }

     
    event LogAPICallsMade(
        uint apiId,
        address indexed sellerAddress,
        address indexed buyerAddress,
        uint pricePerCall,
        uint numCalls,
        uint totalPrice,
        address reportingAddress
    );

     
    event LogAPICallsPaid(
        uint apiId,
        address indexed sellerAddress,
        uint totalPrice,
        uint rewardedTokens,
        uint networkFee
    );

     
    event LogSpendCredits(
        address indexed buyerAddress,
        uint apiId,
        uint amount,
        bool causedAnOverdraft
    );

     
    event LogDepositCredits(
        address indexed buyerAddress,
        uint amount
    );

     
    event LogWithdrawCredits(
        address indexed buyerAddress,
        uint amount
    );

     
     
     
    constructor() public {
        version = 1;

         
         
        tokenReward = 100 * 10**18;

         
        saleFee = 10;

         
        defaultBuyerLastPaidAt = 604800;

         
        withdrawAddress = msg.sender;
        usageReportingAddress = msg.sender;
    }

     
     
     
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20(tokenAddress).transfer(owner, tokens);
    }

     
     
     
    function withdrawEther(uint amount) public {
        require(msg.sender == withdrawAddress);
        require(amount <= this.balance);
        require(amount <= safeWithdrawAmount);
        safeWithdrawAmount = safeWithdrawAmount.sub(amount);
        withdrawAddress.transfer(amount);
    }

     
     
     
    function setWithdrawAddress(address _withdrawAddress) public onlyOwner {
        require(_withdrawAddress != address(0));
        withdrawAddress = _withdrawAddress;
    }

     
     
     
    function setUsageReportingAddress(address _usageReportingAddress) public onlyOwner {
        require(_usageReportingAddress != address(0));
        usageReportingAddress = _usageReportingAddress;
    }

     
     
     
    function setRelayContractAddress(address _relayContractAddress) public onlyOwner {
        require(_relayContractAddress != address(0));
        relayContractAddress = _relayContractAddress;
    }

     
     
     
    function setTokenContractAddress(address _tokenContractAddress) public onlyOwner {
        require(_tokenContractAddress != address(0));
        tokenContractAddress = _tokenContractAddress;
    }

     
     
     
    function setTokenReward(uint _tokenReward) public onlyOwner {
        tokenReward = _tokenReward;
    }

     
     
     
    function setSaleFee(uint _saleFee) public onlyOwner {
        saleFee = _saleFee;
    }

     
     
     
    function setDefaultBuyerLastPaidAt(uint _defaultBuyerLastPaidAt) public onlyOwner {
        defaultBuyerLastPaidAt = _defaultBuyerLastPaidAt;
    }

     
     
     
    function reportUsage(uint apiId, uint numCalls, address buyerAddress) public {
         
        Relay relay = Relay(relayContractAddress);
        address apiRegistryAddress = relay.apiRegistryContractAddress();

         
        APIRegistry apiRegistry = APIRegistry(apiRegistryAddress);

        uint pricePerCall;
        bytes32 sellerUsername;
        bytes32 apiName;
        address sellerAddress;

        (pricePerCall, sellerUsername, apiName, sellerAddress) = apiRegistry.getApiByIdWithoutDynamics(apiId);

         
        require(sellerAddress != address(0));
        require(msg.sender == sellerAddress || msg.sender == usageReportingAddress);

         
        require(sellerUsername != "" && apiName != "");

        uint totalPrice = pricePerCall.mul(numCalls);

        require(totalPrice > 0);

        APIBalance storage apiBalance = owed[apiId];

        if (apiBalance.amounts[buyerAddress] == 0) {
             
            apiBalance.nonzeroAddresses.push(buyerAddress);
        }

        apiBalance.amounts[buyerAddress] = apiBalance.amounts[buyerAddress].add(totalPrice);

        emit LogAPICallsMade(
            apiId,
            sellerAddress,
            buyerAddress,
            pricePerCall,
            numCalls,
            totalPrice,
            msg.sender
        );
    }

     
     
     
     
    function paySellerForBuyer(uint apiId, address buyerAddress) public {
         
        Relay relay = Relay(relayContractAddress);
        address apiRegistryAddress = relay.apiRegistryContractAddress();

         
        APIRegistry apiRegistry = APIRegistry(apiRegistryAddress);

        uint pricePerCall;
        bytes32 sellerUsername;
        bytes32 apiName;
        address sellerAddress;

        (pricePerCall, sellerUsername, apiName, sellerAddress) = apiRegistry.getApiByIdWithoutDynamics(apiId);

         
        require(pricePerCall != 0 && sellerUsername != "" && apiName != "" && sellerAddress != address(0));

        uint buyerPaid = processSalesForSingleBuyer(apiId, buyerAddress);

        if (buyerPaid == 0) {
            return;  
        }

         
        uint fee = buyerPaid.mul(saleFee).div(100);
        uint payout = buyerPaid.sub(fee);

         
        safeWithdrawAmount += fee;

        emit LogAPICallsPaid(
            apiId,
            sellerAddress,
            buyerPaid,
            tokenReward,
            fee
        );

         
        rewardTokens(sellerAddress, tokenReward);

         
        sellerAddress.transfer(payout);
    }

     
     
     
     
    function paySeller(uint apiId) public {
         
        Relay relay = Relay(relayContractAddress);
        address apiRegistryAddress = relay.apiRegistryContractAddress();

         
        APIRegistry apiRegistry = APIRegistry(apiRegistryAddress);

        uint pricePerCall;
        bytes32 sellerUsername;
        bytes32 apiName;
        address sellerAddress;

        (pricePerCall, sellerUsername, apiName, sellerAddress) = apiRegistry.getApiByIdWithoutDynamics(apiId);

         
        require(pricePerCall != 0 && sellerUsername != "" && apiName != "" && sellerAddress != address(0));

         
        uint totalPayable = 0;
        uint totalBuyers = 0;
        (totalPayable, totalBuyers) = processSalesForAllBuyers(apiId);

        if (totalPayable == 0) {
            return;  
        }

         
        uint fee = totalPayable.mul(saleFee).div(100);
        uint payout = totalPayable.sub(fee);

         
        safeWithdrawAmount += fee;

         
        uint totalTokenReward = tokenReward.mul(totalBuyers);

        emit LogAPICallsPaid(
            apiId,
            sellerAddress,
            totalPayable,
            totalTokenReward,
            fee
        );

         
        rewardTokens(sellerAddress, totalTokenReward);

         
        sellerAddress.transfer(payout);
    } 

     
     
     
    function buyerLastPaidAt(uint apiId, address buyerAddress) public view returns (uint) {
        APIBalance storage apiBalance = owed[apiId];
        return apiBalance.buyerLastPaidAt[buyerAddress];
    }   

     
     
     
    function buyerInfoOf(address addr) 
        public 
        view 
        returns (
            bool overdrafted, 
            uint lifetimeOverdraftCount, 
            uint credits, 
            uint lifetimeCreditsUsed, 
            uint lifetimeExceededApprovalAmountCount
        ) 
    {
        BuyerInfo storage buyer = buyers[addr];
        overdrafted = buyer.overdrafted;
        lifetimeOverdraftCount = buyer.lifetimeOverdraftCount;
        credits = buyer.credits;
        lifetimeCreditsUsed = buyer.lifetimeCreditsUsed;
        lifetimeExceededApprovalAmountCount = buyer.lifetimeExceededApprovalAmountCount;
    }

     
     
     
    function creditsBalanceOf(address addr) public view returns (uint) {
        BuyerInfo storage buyer = buyers[addr];
        return buyer.credits;
    }

     
     
     
    function addCredits(address to) public payable {
        BuyerInfo storage buyer = buyers[to];
        buyer.credits = buyer.credits.add(msg.value);
        emit LogDepositCredits(to, msg.value);
    }

     
     
     
    function withdrawCredits(uint amount) public {
        BuyerInfo storage buyer = buyers[msg.sender];
        require(buyer.credits >= amount);
        buyer.credits = buyer.credits.sub(amount);
        msg.sender.transfer(amount);
        emit LogWithdrawCredits(msg.sender, amount);
    }

     
     
     
    function nonzeroAddressesElementForApi(uint apiId, uint index) public view returns (address) {
        APIBalance storage apiBalance = owed[apiId];
        return apiBalance.nonzeroAddresses[index];
    }

     
     
     
    function nonzeroAddressesLengthForApi(uint apiId) public view returns (uint) {
        APIBalance storage apiBalance = owed[apiId];
        return apiBalance.nonzeroAddresses.length;
    }

     
     
     
    function amountOwedForApiForBuyer(uint apiId, address buyerAddress) public view returns (uint) {
        APIBalance storage apiBalance = owed[apiId];
        return apiBalance.amounts[buyerAddress];
    }

     
     
     
    function totalOwedForApi(uint apiId) public view returns (uint) {
        APIBalance storage apiBalance = owed[apiId];

        uint totalOwed = 0;
        for (uint i = 0; i < apiBalance.nonzeroAddresses.length; i++) {
            address buyerAddress = apiBalance.nonzeroAddresses[i];
            uint buyerOwes = apiBalance.amounts[buyerAddress];
            totalOwed = totalOwed.add(buyerOwes);
        }

        return totalOwed;
    }

     
     
     
    function approvedAmount(uint apiId, address buyerAddress) public view returns (uint) {
        return buyers[buyerAddress].approvedAmounts[apiId];
    }

     
     
     
    function approveAmount(uint apiId, address buyerAddress, uint newAmount) public {
        require(buyerAddress != address(0) && apiId != 0);

         
        require(msg.sender == buyerAddress || msg.sender == usageReportingAddress);

        BuyerInfo storage buyer = buyers[buyerAddress];
        buyer.approvedAmounts[apiId] = newAmount;
    }

     
     
     
     
     
     
     
    function approveAmountAndSetFirstUseTime(
        uint apiId, 
        address buyerAddress, 
        uint newAmount, 
        uint firstUseTime
    ) 
        public 
    {
        require(buyerAddress != address(0) && apiId != 0);

         
        require(msg.sender == buyerAddress || msg.sender == usageReportingAddress);

        APIBalance storage apiBalance = owed[apiId];
        require(apiBalance.buyerLastPaidAt[buyerAddress] == 0);

        apiBalance.buyerLastPaidAt[buyerAddress] = firstUseTime;
        
        BuyerInfo storage buyer = buyers[buyerAddress];
        buyer.approvedAmounts[apiId] = newAmount;

    }

     
     
     
    function buyerExceededApprovedAmount(uint apiId, address buyerAddress) public view returns (bool) {
        return buyers[buyerAddress].exceededApprovedAmount[apiId];
    }

     
     
     
    function rewardTokens(address toReward, uint amount) private {
        DeconetToken token = DeconetToken(tokenContractAddress);
        address tokenOwner = token.owner();

         
        uint tokenOwnerBalance = token.balanceOf(tokenOwner);
        uint tokenOwnerAllowance = token.allowance(tokenOwner, address(this));
        if (tokenOwnerBalance >= amount && tokenOwnerAllowance >= amount) {
            token.transferFrom(tokenOwner, toReward, amount);
        }
    }

     
     
     
    function processSalesForSingleBuyer(uint apiId, address buyerAddress) private returns (uint) {
        APIBalance storage apiBalance = owed[apiId];

        uint buyerOwes = apiBalance.amounts[buyerAddress];
        uint buyerLastPaidAtTime = apiBalance.buyerLastPaidAt[buyerAddress];
        if (buyerLastPaidAtTime == 0) {
             
            buyerLastPaidAtTime = now - defaultBuyerLastPaidAt;  
        }
        uint elapsedSecondsSinceLastPayout = now - buyerLastPaidAtTime;
        uint buyerNowOwes = buyerOwes;
        uint buyerPaid = 0;
        bool overdrafted = false;

        (buyerPaid, overdrafted) = chargeBuyer(apiId, buyerAddress, elapsedSecondsSinceLastPayout, buyerOwes);

        buyerNowOwes = buyerOwes.sub(buyerPaid);
        apiBalance.amounts[buyerAddress] = buyerNowOwes;

         
        if (buyerNowOwes != 0) {
            removeAddressFromNonzeroBalancesArray(apiId, buyerAddress);
        }
         
        if (buyerPaid == 0) {
            return 0;
        }

         
        emit LogSpendCredits(buyerAddress, apiId, buyerPaid, overdrafted);

         
        apiBalance.buyerLastPaidAt[buyerAddress] = now;
        
        return buyerPaid;
    }

     
     
     
    function processSalesForAllBuyers(uint apiId) private returns (uint totalPayable, uint totalBuyers) {
        APIBalance storage apiBalance = owed[apiId];

        uint currentTime = now;
        address[] memory oldNonzeroAddresses = apiBalance.nonzeroAddresses;
        apiBalance.nonzeroAddresses = new address[](0);

        for (uint i = 0; i < oldNonzeroAddresses.length; i++) {
            address buyerAddress = oldNonzeroAddresses[i];
            uint buyerOwes = apiBalance.amounts[buyerAddress];
            uint buyerLastPaidAtTime = apiBalance.buyerLastPaidAt[buyerAddress];
            if (buyerLastPaidAtTime == 0) {
                 
                buyerLastPaidAtTime = now - defaultBuyerLastPaidAt;  
            }
            uint elapsedSecondsSinceLastPayout = currentTime - buyerLastPaidAtTime;
            uint buyerNowOwes = buyerOwes;
            uint buyerPaid = 0;
            bool overdrafted = false;

            (buyerPaid, overdrafted) = chargeBuyer(apiId, buyerAddress, elapsedSecondsSinceLastPayout, buyerOwes);

            totalPayable = totalPayable.add(buyerPaid);
            buyerNowOwes = buyerOwes.sub(buyerPaid);
            apiBalance.amounts[buyerAddress] = buyerNowOwes;

             
            if (buyerNowOwes != 0) {
                apiBalance.nonzeroAddresses.push(buyerAddress);
            }
             
            if (buyerPaid != 0) {
                 
                emit LogSpendCredits(buyerAddress, apiId, buyerPaid, overdrafted);

                 
                apiBalance.buyerLastPaidAt[buyerAddress] = now;

                 
                totalBuyers += 1;
            }
        }
    }

     
     
     
     
     
     
     
     
    function chargeBuyer(
        uint apiId, 
        address buyerAddress, 
        uint elapsedSecondsSinceLastPayout, 
        uint buyerOwes
    ) 
        private 
        returns (
            uint paid, 
            bool overdrafted
        ) 
    {
        BuyerInfo storage buyer = buyers[buyerAddress];
        uint approvedAmountPerSecond = buyer.approvedAmounts[apiId];
        uint approvedAmountSinceLastPayout = approvedAmountPerSecond.mul(elapsedSecondsSinceLastPayout);
        
         
        if (buyer.credits >= buyerOwes) {
             
            overdrafted = false;
            buyer.overdrafted = false;

             
            if (approvedAmountSinceLastPayout >= buyerOwes) {
                 
                 
                buyer.exceededApprovedAmount[apiId] = false;

                 
                paid = buyerOwes;

            } else {
                 
                 
                buyer.exceededApprovedAmount[apiId] = true;
                buyer.lifetimeExceededApprovalAmountCount += 1;

                 
                paid = approvedAmountSinceLastPayout;
            }
        } else {
             
            overdrafted = true;
            buyer.overdrafted = true;
            buyer.lifetimeOverdraftCount += 1;

             
            if (buyer.credits >= approvedAmountSinceLastPayout) {
                 
                paid = approvedAmountSinceLastPayout;

            } else {
                 
                 
                paid = buyer.credits;
            }
        }

        buyer.credits = buyer.credits.sub(paid);
        buyer.lifetimeCreditsUsed = buyer.lifetimeCreditsUsed.add(paid);
    }

    function removeAddressFromNonzeroBalancesArray(uint apiId, address toRemove) private {
        APIBalance storage apiBalance = owed[apiId];

        bool foundElement = false;

        for (uint i = 0; i < apiBalance.nonzeroAddresses.length-1; i++) {
            if (apiBalance.nonzeroAddresses[i] == toRemove) {
                foundElement = true;
            }
            if (foundElement == true) {
                apiBalance.nonzeroAddresses[i] = apiBalance.nonzeroAddresses[i+1];
            }
        }
        if (foundElement == true) {
            apiBalance.nonzeroAddresses.length--;
        }
    }
}