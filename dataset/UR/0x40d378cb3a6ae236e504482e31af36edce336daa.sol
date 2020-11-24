 

pragma solidity 0.4.24;

 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256 result) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    require(c / a == b, "Error: Unsafe multiplication operation!");
    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256 result) {
     
    uint256 c = a / b;
     
    return c;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256 result) {
     
    require(b <= a, "Error: Unsafe subtraction operation!");
    return a - b;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256 result) {
    uint256 c = a + b;
    require(c >= a, "Error: Unsafe addition operation!");
    return c;
  }
}


 
contract Ownable {

  mapping(address => bool) public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
  event AllowOwnership(address indexed allowedAddress);
  event RevokeOwnership(address indexed allowedAddress);

   
  constructor() public {
    owner[msg.sender] = true;
  }

   
  modifier onlyOwner() {
    require(owner[msg.sender], "Error: Transaction sender is not allowed by the contract.");
    _;
  }

   
  function transferOwnership(address newOwner) public onlyOwner returns (bool success) {
    require(newOwner != address(0), "Error: newOwner cannot be null!");
    emit OwnershipTransferred(msg.sender, newOwner);
    owner[newOwner] = true;
    owner[msg.sender] = false;
    return true;
  }

   
  function allowOwnership(address allowedAddress) public onlyOwner returns (bool success) {
    owner[allowedAddress] = true;
    emit AllowOwnership(allowedAddress);
    return true;
  }

   
  function removeOwnership(address allowedAddress) public onlyOwner returns (bool success) {
    owner[allowedAddress] = false;
    emit RevokeOwnership(allowedAddress);
    return true;
  }

}


 
contract TokenIOStorage is Ownable {


     
		 
		 
		 
		 
    mapping(bytes32 => uint256)    internal uIntStorage;
    mapping(bytes32 => string)     internal stringStorage;
    mapping(bytes32 => address)    internal addressStorage;
    mapping(bytes32 => bytes)      internal bytesStorage;
    mapping(bytes32 => bool)       internal boolStorage;
    mapping(bytes32 => int256)     internal intStorage;

    constructor() public {
				 
				 
				 
        owner[msg.sender] = true;
    }

     

     
    function setAddress(bytes32 _key, address _value) public onlyOwner returns (bool success) {
        addressStorage[_key] = _value;
        return true;
    }

     
    function setUint(bytes32 _key, uint _value) public onlyOwner returns (bool success) {
        uIntStorage[_key] = _value;
        return true;
    }

     
    function setString(bytes32 _key, string _value) public onlyOwner returns (bool success) {
        stringStorage[_key] = _value;
        return true;
    }

     
    function setBytes(bytes32 _key, bytes _value) public onlyOwner returns (bool success) {
        bytesStorage[_key] = _value;
        return true;
    }

     
    function setBool(bytes32 _key, bool _value) public onlyOwner returns (bool success) {
        boolStorage[_key] = _value;
        return true;
    }

     
    function setInt(bytes32 _key, int _value) public onlyOwner returns (bool success) {
        intStorage[_key] = _value;
        return true;
    }

     
		 
		 

     
    function deleteAddress(bytes32 _key) public onlyOwner returns (bool success) {
        delete addressStorage[_key];
        return true;
    }

     
    function deleteUint(bytes32 _key) public onlyOwner returns (bool success) {
        delete uIntStorage[_key];
        return true;
    }

     
    function deleteString(bytes32 _key) public onlyOwner returns (bool success) {
        delete stringStorage[_key];
        return true;
    }

     
    function deleteBytes(bytes32 _key) public onlyOwner returns (bool success) {
        delete bytesStorage[_key];
        return true;
    }

     
    function deleteBool(bytes32 _key) public onlyOwner returns (bool success) {
        delete boolStorage[_key];
        return true;
    }

     
    function deleteInt(bytes32 _key) public onlyOwner returns (bool success) {
        delete intStorage[_key];
        return true;
    }

     

     
    function getAddress(bytes32 _key) public view returns (address _value) {
        return addressStorage[_key];
    }

     
    function getUint(bytes32 _key) public view returns (uint _value) {
        return uIntStorage[_key];
    }

     
    function getString(bytes32 _key) public view returns (string _value) {
        return stringStorage[_key];
    }

     
    function getBytes(bytes32 _key) public view returns (bytes _value) {
        return bytesStorage[_key];
    }

     
    function getBool(bytes32 _key) public view returns (bool _value) {
        return boolStorage[_key];
    }

     
    function getInt(bytes32 _key) public view returns (int _value) {
        return intStorage[_key];
    }

}


 


library TokenIOLib {

   
  using SafeMath for uint;

   
  struct Data {
    TokenIOStorage Storage;
  }

   
  event Approval(address indexed owner, address indexed spender, uint amount);
  event Deposit(string currency, address indexed account, uint amount, string issuerFirm);
  event Withdraw(string currency, address indexed account, uint amount, string issuerFirm);
  event Transfer(string currency, address indexed from, address indexed to, uint amount, bytes data);
  event KYCApproval(address indexed account, bool status, string issuerFirm);
  event AccountStatus(address indexed account, bool status, string issuerFirm);
  event FxSwap(string tokenASymbol,string tokenBSymbol,uint tokenAValue,uint tokenBValue, uint expiration, bytes32 transactionHash);
  event AccountForward(address indexed originalAccount, address indexed forwardedAccount);
  event NewAuthority(address indexed authority, string issuerFirm);

   
  function setTokenName(Data storage self, string tokenName) internal returns (bool success) {
    bytes32 id = keccak256(abi.encodePacked('token.name', address(this)));
    require(
      self.Storage.setString(id, tokenName),
      "Error: Unable to set storage value. Please ensure contract interface is allowed by the storage contract."
    );
    return true;
  }

   
  function setTokenSymbol(Data storage self, string tokenSymbol) internal returns (bool success) {
    bytes32 id = keccak256(abi.encodePacked('token.symbol', address(this)));
    require(
      self.Storage.setString(id, tokenSymbol),
      "Error: Unable to set storage value. Please ensure contract interface is allowed by the storage contract."
    );
    return true;
  }

   
  function setTokenTLA(Data storage self, string tokenTLA) internal returns (bool success) {
    bytes32 id = keccak256(abi.encodePacked('token.tla', address(this)));
    require(
      self.Storage.setString(id, tokenTLA),
      "Error: Unable to set storage value. Please ensure contract interface is allowed by the storage contract."
    );
    return true;
  }

   
  function setTokenVersion(Data storage self, string tokenVersion) internal returns (bool success) {
    bytes32 id = keccak256(abi.encodePacked('token.version', address(this)));
    require(
      self.Storage.setString(id, tokenVersion),
      "Error: Unable to set storage value. Please ensure contract interface is allowed by the storage contract."
    );
    return true;
  }

   
  function setTokenDecimals(Data storage self, string currency, uint tokenDecimals) internal returns (bool success) {
    bytes32 id = keccak256(abi.encodePacked('token.decimals', currency));
    require(
      self.Storage.setUint(id, tokenDecimals),
      "Error: Unable to set storage value. Please ensure contract interface is allowed by the storage contract."
    );
    return true;
  }

   
  function setFeeBPS(Data storage self, uint feeBPS) internal returns (bool success) {
    bytes32 id = keccak256(abi.encodePacked('fee.bps', address(this)));
    require(
      self.Storage.setUint(id, feeBPS),
      "Error: Unable to set storage value. Please ensure contract interface is allowed by the storage contract."
    );
    return true;
  }

   
  function setFeeMin(Data storage self, uint feeMin) internal returns (bool success) {
    bytes32 id = keccak256(abi.encodePacked('fee.min', address(this)));
    require(
      self.Storage.setUint(id, feeMin),
      "Error: Unable to set storage value. Please ensure contract interface is allowed by the storage contract."
    );
    return true;
  }

   
  function setFeeMax(Data storage self, uint feeMax) internal returns (bool success) {
    bytes32 id = keccak256(abi.encodePacked('fee.max', address(this)));
    require(
      self.Storage.setUint(id, feeMax),
      "Error: Unable to set storage value. Please ensure contract interface is allowed by the storage contract."
    );
    return true;
  }

   
  function setFeeFlat(Data storage self, uint feeFlat) internal returns (bool success) {
    bytes32 id = keccak256(abi.encodePacked('fee.flat', address(this)));
    require(
      self.Storage.setUint(id, feeFlat),
      "Error: Unable to set storage value. Please ensure contract interface is allowed by the storage contract."
    );
    return true;
  }

   
  function setFeeMsg(Data storage self, bytes feeMsg) internal returns (bool success) {
    bytes32 id = keccak256(abi.encodePacked('fee.msg', address(this)));
    require(
      self.Storage.setBytes(id, feeMsg),
      "Error: Unable to set storage value. Please ensure contract interface is allowed by the storage contract."
    );
    return true;
  }

   
  function setFeeContract(Data storage self, address feeContract) internal returns (bool success) {
    bytes32 id = keccak256(abi.encodePacked('fee.account', address(this)));
    require(
      self.Storage.setAddress(id, feeContract),
      "Error: Unable to set storage value. Please ensure contract interface is allowed by the storage contract."
    );
    return true;
  }

   
  function setTokenNameSpace(Data storage self, string currency) internal returns (bool success) {
    bytes32 id = keccak256(abi.encodePacked('token.namespace', currency));
    require(
      self.Storage.setAddress(id, address(this)),
      "Error: Unable to set storage value. Please ensure contract interface is allowed by the storage contract."
    );
    return true;
  }

   
  function setKYCApproval(Data storage self, address account, bool isApproved, string issuerFirm) internal returns (bool success) {
      bytes32 id = keccak256(abi.encodePacked('account.kyc', getForwardedAccount(self, account)));
      require(
        self.Storage.setBool(id, isApproved),
        "Error: Unable to set storage value. Please ensure contract interface is allowed by the storage contract."
      );

       
      emit KYCApproval(account, isApproved, issuerFirm);
      return true;
  }

   
  function setAccountStatus(Data storage self, address account, bool isAllowed, string issuerFirm) internal returns (bool success) {
    bytes32 id = keccak256(abi.encodePacked('account.allowed', getForwardedAccount(self, account)));
    require(
      self.Storage.setBool(id, isAllowed),
      "Error: Unable to set storage value. Please ensure contract interface is allowed by the storage contract."
    );

     
    emit AccountStatus(account, isAllowed, issuerFirm);
    return true;
  }


   
  function setForwardedAccount(Data storage self, address originalAccount, address forwardedAccount) internal returns (bool success) {
    bytes32 id = keccak256(abi.encodePacked('master.account', forwardedAccount));
    require(
      self.Storage.setAddress(id, originalAccount),
      "Error: Unable to set storage value. Please ensure contract interface is allowed by the storage contract."
    );
    return true;
  }

   
  function getForwardedAccount(Data storage self, address account) internal view returns (address registeredAccount) {
    bytes32 id = keccak256(abi.encodePacked('master.account', account));
    address originalAccount = self.Storage.getAddress(id);
    if (originalAccount != 0x0) {
      return originalAccount;
    } else {
      return account;
    }
  }

   
  function getKYCApproval(Data storage self, address account) internal view returns (bool status) {
      bytes32 id = keccak256(abi.encodePacked('account.kyc', getForwardedAccount(self, account)));
      return self.Storage.getBool(id);
  }

   
  function getAccountStatus(Data storage self, address account) internal view returns (bool status) {
    bytes32 id = keccak256(abi.encodePacked('account.allowed', getForwardedAccount(self, account)));
    return self.Storage.getBool(id);
  }

   
  function getTokenNameSpace(Data storage self, string currency) internal view returns (address contractAddress) {
    bytes32 id = keccak256(abi.encodePacked('token.namespace', currency));
    return self.Storage.getAddress(id);
  }

   
  function getTokenName(Data storage self, address contractAddress) internal view returns (string tokenName) {
    bytes32 id = keccak256(abi.encodePacked('token.name', contractAddress));
    return self.Storage.getString(id);
  }

   
  function getTokenSymbol(Data storage self, address contractAddress) internal view returns (string tokenSymbol) {
    bytes32 id = keccak256(abi.encodePacked('token.symbol', contractAddress));
    return self.Storage.getString(id);
  }

   
  function getTokenTLA(Data storage self, address contractAddress) internal view returns (string tokenTLA) {
    bytes32 id = keccak256(abi.encodePacked('token.tla', contractAddress));
    return self.Storage.getString(id);
  }

   
  function getTokenVersion(Data storage self, address contractAddress) internal view returns (string) {
    bytes32 id = keccak256(abi.encodePacked('token.version', contractAddress));
    return self.Storage.getString(id);
  }

   
  function getTokenDecimals(Data storage self, string currency) internal view returns (uint tokenDecimals) {
    bytes32 id = keccak256(abi.encodePacked('token.decimals', currency));
    return self.Storage.getUint(id);
  }

   
  function getFeeBPS(Data storage self, address contractAddress) internal view returns (uint feeBps) {
    bytes32 id = keccak256(abi.encodePacked('fee.bps', contractAddress));
    return self.Storage.getUint(id);
  }

   
  function getFeeMin(Data storage self, address contractAddress) internal view returns (uint feeMin) {
    bytes32 id = keccak256(abi.encodePacked('fee.min', contractAddress));
    return self.Storage.getUint(id);
  }

   
  function getFeeMax(Data storage self, address contractAddress) internal view returns (uint feeMax) {
    bytes32 id = keccak256(abi.encodePacked('fee.max', contractAddress));
    return self.Storage.getUint(id);
  }

   
  function getFeeFlat(Data storage self, address contractAddress) internal view returns (uint feeFlat) {
    bytes32 id = keccak256(abi.encodePacked('fee.flat', contractAddress));
    return self.Storage.getUint(id);
  }

   
  function getFeeMsg(Data storage self, address contractAddress) internal view returns (bytes feeMsg) {
    bytes32 id = keccak256(abi.encodePacked('fee.msg', contractAddress));
    return self.Storage.getBytes(id);
  }

   
  function setMasterFeeContract(Data storage self, address contractAddress) internal returns (bool success) {
    bytes32 id = keccak256(abi.encodePacked('fee.contract.master'));
    require(
      self.Storage.setAddress(id, contractAddress),
      "Error: Unable to set storage value. Please ensure contract interface is allowed by the storage contract."
    );
    return true;
  }

   
  function getMasterFeeContract(Data storage self) internal view returns (address masterFeeContract) {
    bytes32 id = keccak256(abi.encodePacked('fee.contract.master'));
    return self.Storage.getAddress(id);
  }

   
  function getFeeContract(Data storage self, address contractAddress) internal view returns (address feeContract) {
    bytes32 id = keccak256(abi.encodePacked('fee.account', contractAddress));

    address feeAccount = self.Storage.getAddress(id);
    if (feeAccount == 0x0) {
      return getMasterFeeContract(self);
    } else {
      return feeAccount;
    }
  }

   
  function getTokenSupply(Data storage self, string currency) internal view returns (uint supply) {
    bytes32 id = keccak256(abi.encodePacked('token.supply', currency));
    return self.Storage.getUint(id);
  }

   
  function getTokenAllowance(Data storage self, string currency, address account, address spender) internal view returns (uint allowance) {
    bytes32 id = keccak256(abi.encodePacked('token.allowance', currency, getForwardedAccount(self, account), getForwardedAccount(self, spender)));
    return self.Storage.getUint(id);
  }

   
  function getTokenBalance(Data storage self, string currency, address account) internal view returns (uint balance) {
    bytes32 id = keccak256(abi.encodePacked('token.balance', currency, getForwardedAccount(self, account)));
    return self.Storage.getUint(id);
  }

   
  function getTokenFrozenBalance(Data storage self, string currency, address account) internal view returns (uint frozenBalance) {
    bytes32 id = keccak256(abi.encodePacked('token.frozen', currency, getForwardedAccount(self, account)));
    return self.Storage.getUint(id);
  }

   
  function setTokenFrozenBalance(Data storage self, string currency, address account, uint amount) internal returns (bool success) {
    bytes32 id = keccak256(abi.encodePacked('token.frozen', currency, getForwardedAccount(self, account)));
    require(
      self.Storage.setUint(id, amount),
      "Error: Unable to set storage value. Please ensure contract interface is allowed by the storage contract."
    );
    return true;
  }

   
  function calculateFees(Data storage self, address contractAddress, uint amount) internal view returns (uint calculatedFees) {

    uint maxFee = self.Storage.getUint(keccak256(abi.encodePacked('fee.max', contractAddress)));
    uint minFee = self.Storage.getUint(keccak256(abi.encodePacked('fee.min', contractAddress)));
    uint bpsFee = self.Storage.getUint(keccak256(abi.encodePacked('fee.bps', contractAddress)));
    uint flatFee = self.Storage.getUint(keccak256(abi.encodePacked('fee.flat', contractAddress)));
    uint fees = ((amount.mul(bpsFee)).div(10000)).add(flatFee);

    if (fees > maxFee) {
      return maxFee;
    } else if (fees < minFee) {
      return minFee;
    } else {
      return fees;
    }
  }

   
  function verifyAccounts(Data storage self, address accountA, address accountB) internal view returns (bool verified) {
    require(
      verifyAccount(self, accountA),
      "Error: Account is not verified for operation. Please ensure account has been KYC approved."
    );
    require(
      verifyAccount(self, accountB),
      "Error: Account is not verified for operation. Please ensure account has been KYC approved."
    );
    return true;
  }

   
  function verifyAccount(Data storage self, address account) internal view returns (bool verified) {
    require(
      getKYCApproval(self, account),
      "Error: Account does not have KYC approval."
    );
    require(
      getAccountStatus(self, account),
      "Error: Account status is `false`. Account status must be `true`."
    );
    return true;
  }


   
  function transfer(Data storage self, string currency, address to, uint amount, bytes data) internal returns (bool success) {
    require(address(to) != 0x0, "Error: `to` address cannot be null." );
    require(amount > 0, "Error: `amount` must be greater than zero");

    address feeContract = getFeeContract(self, address(this));
    uint fees = calculateFees(self, feeContract, amount);

    require(
      setAccountSpendingAmount(self, msg.sender, getFxUSDAmount(self, currency, amount)),
      "Error: Unable to set spending amount for account.");

    require(
      forceTransfer(self, currency, msg.sender, to, amount, data),
      "Error: Unable to transfer funds to account.");

     
    require(
      forceTransfer(self, currency, msg.sender, feeContract, fees, getFeeMsg(self, feeContract)),
      "Error: Unable to transfer fees to fee contract.");

    return true;
  }

   
  function transferFrom(Data storage self, string currency, address from, address to, uint amount, bytes data) internal returns (bool success) {
    require(
      address(to) != 0x0,
      "Error: `to` address must not be null."
    );

    address feeContract = getFeeContract(self, address(this));
    uint fees = calculateFees(self, feeContract, amount);

     
    require(
      setAccountSpendingAmount(self, from, getFxUSDAmount(self, currency, amount)),
      "Error: Unable to set account spending amount."
    );

     
    require(
      forceTransfer(self, currency, from, to, amount, data),
      "Error: Unable to transfer funds to account."
    );

     
    require(
      forceTransfer(self, currency, from, feeContract, fees, getFeeMsg(self, feeContract)),
      "Error: Unable to transfer fees to fee contract."
    );

     
    require(
      updateAllowance(self, currency, from, amount),
      "Error: Unable to update allowance for spender."
    );

    return true;
  }

   
  function forceTransfer(Data storage self, string currency, address from, address to, uint amount, bytes data) internal returns (bool success) {
    require(
      address(to) != 0x0,
      "Error: `to` address must not be null."
    );

    bytes32 id_a = keccak256(abi.encodePacked('token.balance', currency, getForwardedAccount(self, from)));
    bytes32 id_b = keccak256(abi.encodePacked('token.balance', currency, getForwardedAccount(self, to)));

    require(
      self.Storage.setUint(id_a, self.Storage.getUint(id_a).sub(amount)),
      "Error: Unable to set storage value. Please ensure contract has allowed permissions with storage contract."
    );
    require(
      self.Storage.setUint(id_b, self.Storage.getUint(id_b).add(amount)),
      "Error: Unable to set storage value. Please ensure contract has allowed permissions with storage contract."
    );

    emit Transfer(currency, from, to, amount, data);

    return true;
  }

   
  function updateAllowance(Data storage self, string currency, address account, uint amount) internal returns (bool success) {
    bytes32 id = keccak256(abi.encodePacked('token.allowance', currency, getForwardedAccount(self, account), getForwardedAccount(self, msg.sender)));
    require(
      self.Storage.setUint(id, self.Storage.getUint(id).sub(amount)),
      "Error: Unable to set storage value. Please ensure contract has allowed permissions with storage contract."
    );
    return true;
  }

   
  function approveAllowance(Data storage self, address spender, uint amount) internal returns (bool success) {
    require(spender != 0x0,
        "Error: `spender` address cannot be null.");

    string memory currency = getTokenSymbol(self, address(this));

    require(
      getTokenFrozenBalance(self, currency, getForwardedAccount(self, spender)) == 0,
      "Error: Spender must not have a frozen balance directly");

    bytes32 id_a = keccak256(abi.encodePacked('token.allowance', currency, getForwardedAccount(self, msg.sender), getForwardedAccount(self, spender)));
    bytes32 id_b = keccak256(abi.encodePacked('token.balance', currency, getForwardedAccount(self, msg.sender)));

    require(
      self.Storage.getUint(id_a) == 0 || amount == 0,
      "Error: Allowance must be zero (0) before setting an updated allowance for spender.");

    require(
      self.Storage.getUint(id_b) >= amount,
      "Error: Allowance cannot exceed msg.sender token balance.");

    require(
      self.Storage.setUint(id_a, amount),
      "Error: Unable to set storage value. Please ensure contract has allowed permissions with storage contract.");

    emit Approval(msg.sender, spender, amount);

    return true;
  }

   
  function deposit(Data storage self, string currency, address account, uint amount, string issuerFirm) internal returns (bool success) {
    bytes32 id_a = keccak256(abi.encodePacked('token.balance', currency, getForwardedAccount(self, account)));
    bytes32 id_b = keccak256(abi.encodePacked('token.issued', currency, issuerFirm));
    bytes32 id_c = keccak256(abi.encodePacked('token.supply', currency));


    require(self.Storage.setUint(id_a, self.Storage.getUint(id_a).add(amount)),
      "Error: Unable to set storage value. Please ensure contract has allowed permissions with storage contract.");
    require(self.Storage.setUint(id_b, self.Storage.getUint(id_b).add(amount)),
      "Error: Unable to set storage value. Please ensure contract has allowed permissions with storage contract.");
    require(self.Storage.setUint(id_c, self.Storage.getUint(id_c).add(amount)),
      "Error: Unable to set storage value. Please ensure contract has allowed permissions with storage contract.");

    emit Deposit(currency, account, amount, issuerFirm);

    return true;

  }

   
  function withdraw(Data storage self, string currency, address account, uint amount, string issuerFirm) internal returns (bool success) {
    bytes32 id_a = keccak256(abi.encodePacked('token.balance', currency, getForwardedAccount(self, account)));
    bytes32 id_b = keccak256(abi.encodePacked('token.issued', currency, issuerFirm));  
    bytes32 id_c = keccak256(abi.encodePacked('token.supply', currency));

    require(
      self.Storage.setUint(id_a, self.Storage.getUint(id_a).sub(amount)),
      "Error: Unable to set storage value. Please ensure contract has allowed permissions with storage contract.");
    require(
      self.Storage.setUint(id_b, self.Storage.getUint(id_b).sub(amount)),
      "Error: Unable to set storage value. Please ensure contract has allowed permissions with storage contract.");
    require(
      self.Storage.setUint(id_c, self.Storage.getUint(id_c).sub(amount)),
      "Error: Unable to set storage value. Please ensure contract has allowed permissions with storage contract.");

    emit Withdraw(currency, account, amount, issuerFirm);

    return true;

  }

   
  function setRegisteredFirm(Data storage self, string issuerFirm, bool approved) internal returns (bool success) {
    bytes32 id = keccak256(abi.encodePacked('registered.firm', issuerFirm));
    require(
      self.Storage.setBool(id, approved),
      "Error: Unable to set storage value. Please ensure contract has allowed permissions with storage contract."
    );
    return true;
  }

   
  function setRegisteredAuthority(Data storage self, string issuerFirm, address authorityAddress, bool approved) internal returns (bool success) {
    require(
      isRegisteredFirm(self, issuerFirm),
      "Error: `issuerFirm` must be registered.");

    bytes32 id_a = keccak256(abi.encodePacked('registered.authority', issuerFirm, authorityAddress));
    bytes32 id_b = keccak256(abi.encodePacked('registered.authority.firm', authorityAddress));

    require(
      self.Storage.setBool(id_a, approved),
      "Error: Unable to set storage value. Please ensure contract has allowed permissions with storage contract.");

    require(
      self.Storage.setString(id_b, issuerFirm),
      "Error: Unable to set storage value. Please ensure contract has allowed permissions with storage contract.");


    return true;
  }

   
  function getFirmFromAuthority(Data storage self, address authorityAddress) internal view returns (string issuerFirm) {
    bytes32 id = keccak256(abi.encodePacked('registered.authority.firm', getForwardedAccount(self, authorityAddress)));
    return self.Storage.getString(id);
  }

   
  function isRegisteredFirm(Data storage self, string issuerFirm) internal view returns (bool registered) {
    bytes32 id = keccak256(abi.encodePacked('registered.firm', issuerFirm));
    return self.Storage.getBool(id);
  }

   
  function isRegisteredToFirm(Data storage self, string issuerFirm, address authorityAddress) internal view returns (bool registered) {
    bytes32 id = keccak256(abi.encodePacked('registered.authority', issuerFirm, getForwardedAccount(self, authorityAddress)));
    return self.Storage.getBool(id);
  }

   
  function isRegisteredAuthority(Data storage self, address authorityAddress) internal view returns (bool registered) {
    bytes32 id = keccak256(abi.encodePacked('registered.authority', getFirmFromAuthority(self, getForwardedAccount(self, authorityAddress)), getForwardedAccount(self, authorityAddress)));
    return self.Storage.getBool(id);
  }

   
  function getTxStatus(Data storage self, bytes32 txHash) internal view returns (bool txStatus) {
    bytes32 id = keccak256(abi.encodePacked('tx.status', txHash));
    return self.Storage.getBool(id);
  }

   
  function setTxStatus(Data storage self, bytes32 txHash) internal returns (bool success) {
    bytes32 id = keccak256(abi.encodePacked('tx.status', txHash));
     
    require(!getTxStatus(self, txHash),
      "Error: Transaction status must be false before setting the transaction status.");

     
    require(self.Storage.setBool(id, true),
      "Error: Unable to set storage value. Please ensure contract has allowed permissions with storage contract.");

    return true;
  }

   
  function execSwap(
    Data storage self,
    address requester,
    string symbolA,
    string symbolB,
    uint valueA,
    uint valueB,
    uint8 sigV,
    bytes32 sigR,
    bytes32 sigS,
    uint expiration
  ) internal returns (bool success) {

    bytes32 fxTxHash = keccak256(abi.encodePacked(requester, symbolA, symbolB, valueA, valueB, expiration));

     
     
    require(
      verifyAccounts(self, msg.sender, requester),
      "Error: Only verified accounts can perform currency swaps.");

     
    require(
      setTxStatus(self, fxTxHash),
      "Error: Failed to set transaction status to fulfilled.");

     
    require(expiration >= now, "Error: Transaction has expired!");

     
     
    require(
      ecrecover(fxTxHash, sigV, sigR, sigS) == requester,
      "Error: Address derived from transaction signature does not match the requester address");

     
    require(
      forceTransfer(self, symbolA, msg.sender, requester, valueA, "0x0"),
      "Error: Unable to transfer funds to account.");

    require(
      forceTransfer(self, symbolB, requester, msg.sender, valueB, "0x0"),
      "Error: Unable to transfer funds to account.");

    emit FxSwap(symbolA, symbolB, valueA, valueB, expiration, fxTxHash);

    return true;
  }

   
  function setDeprecatedContract(Data storage self, address contractAddress) internal returns (bool success) {
    require(contractAddress != 0x0,
        "Error: cannot deprecate a null address.");

    bytes32 id = keccak256(abi.encodePacked('depcrecated', contractAddress));

    require(self.Storage.setBool(id, true),
      "Error: Unable to set storage value. Please ensure contract interface is allowed by the storage contract.");

    return true;
  }

   
  function isContractDeprecated(Data storage self, address contractAddress) internal view returns (bool status) {
    bytes32 id = keccak256(abi.encodePacked('depcrecated', contractAddress));
    return self.Storage.getBool(id);
  }

   
  function setAccountSpendingPeriod(Data storage self, address account, uint period) internal returns (bool success) {
    bytes32 id = keccak256(abi.encodePacked('limit.spending.period', account));
    require(self.Storage.setUint(id, period),
      "Error: Unable to set storage value. Please ensure contract interface is allowed by the storage contract.");

    return true;
  }

   
  function getAccountSpendingPeriod(Data storage self, address account) internal view returns (uint period) {
    bytes32 id = keccak256(abi.encodePacked('limit.spending.period', account));
    return self.Storage.getUint(id);
  }

   
  function setAccountSpendingLimit(Data storage self, address account, uint limit) internal returns (bool success) {
    bytes32 id = keccak256(abi.encodePacked('account.spending.limit', account));
    require(self.Storage.setUint(id, limit),
      "Error: Unable to set storage value. Please ensure contract interface is allowed by the storage contract.");

    return true;
  }

   
  function getAccountSpendingLimit(Data storage self, address account) internal view returns (uint limit) {
    bytes32 id = keccak256(abi.encodePacked('account.spending.limit', account));
    return self.Storage.getUint(id);
  }

   
  function setAccountSpendingAmount(Data storage self, address account, uint amount) internal returns (bool success) {

     
    require(updateAccountSpendingPeriod(self, account),
      "Error: Unable to update account spending period.");

    uint updatedAmount = getAccountSpendingAmount(self, account).add(amount);

     
    require(
      getAccountSpendingLimit(self, account) >= updatedAmount,
      "Error: Account cannot exceed its daily spend limit.");

     
    bytes32 id = keccak256(abi.encodePacked('account.spending.amount', account, getAccountSpendingPeriod(self, account)));
    require(self.Storage.setUint(id, updatedAmount),
      "Error: Unable to set storage value. Please ensure contract interface is allowed by the storage contract.");

    return true;
  }

   
  function updateAccountSpendingPeriod(Data storage self, address account) internal returns (bool success) {
    uint begDate = getAccountSpendingPeriod(self, account);
    if (begDate > now) {
      return true;
    } else {
      uint duration = 86400;  
      require(
        setAccountSpendingPeriod(self, account, begDate.add(((now.sub(begDate)).div(duration).add(1)).mul(duration))),
        "Error: Unable to update account spending period.");

      return true;
    }
  }

   
  function getAccountSpendingAmount(Data storage self, address account) internal view returns (uint amount) {
    bytes32 id = keccak256(abi.encodePacked('account.spending.amount', account, getAccountSpendingPeriod(self, account)));
    return self.Storage.getUint(id);
  }

   
  function getAccountSpendingRemaining(Data storage self, address account) internal view returns (uint remainingLimit) {
    return getAccountSpendingLimit(self, account).sub(getAccountSpendingAmount(self, account));
  }

   
  function setFxUSDBPSRate(Data storage self, string currency, uint bpsRate) internal returns (bool success) {
    bytes32 id = keccak256(abi.encodePacked('fx.usd.rate', currency));
    require(
      self.Storage.setUint(id, bpsRate),
      "Error: Unable to update account spending period.");

    return true;
  }

   
  function getFxUSDBPSRate(Data storage self, string currency) internal view returns (uint bpsRate) {
    bytes32 id = keccak256(abi.encodePacked('fx.usd.rate', currency));
    return self.Storage.getUint(id);
  }

   
  function getFxUSDAmount(Data storage self, string currency, uint fxAmount) internal view returns (uint amount) {
    uint usdDecimals = getTokenDecimals(self, 'USDx');
    uint fxDecimals = getTokenDecimals(self, currency);
     
    uint usdAmount = ((fxAmount.mul(getFxUSDBPSRate(self, currency)).div(10000)).mul(10**usdDecimals)).div(10**fxDecimals);
    return usdAmount;
  }


}



 



contract TokenIOERC20 is Ownable {
   
  using TokenIOLib for TokenIOLib.Data;
  TokenIOLib.Data lib;

   
  constructor(address _storageContract) public {
     
     
     
     
    lib.Storage = TokenIOStorage(_storageContract);

     
    owner[msg.sender] = true;
  }


   
  function setParams(
    string _name,
    string _symbol,
    string _tla,
    string _version,
    uint _decimals,
    address _feeContract,
    uint _fxUSDBPSRate
    ) onlyOwner public returns (bool success) {
      require(lib.setTokenName(_name),
        "Error: Unable to set token name. Please check arguments.");
      require(lib.setTokenSymbol(_symbol),
        "Error: Unable to set token symbol. Please check arguments.");
      require(lib.setTokenTLA(_tla),
        "Error: Unable to set token TLA. Please check arguments.");
      require(lib.setTokenVersion(_version),
        "Error: Unable to set token version. Please check arguments.");
      require(lib.setTokenDecimals(_symbol, _decimals),
        "Error: Unable to set token decimals. Please check arguments.");
      require(lib.setFeeContract(_feeContract),
        "Error: Unable to set fee contract. Please check arguments.");
      require(lib.setFxUSDBPSRate(_symbol, _fxUSDBPSRate),
        "Error: Unable to set fx USD basis points rate. Please check arguments.");
      return true;
    }

     
    function name() public view returns (string _name) {
      return lib.getTokenName(address(this));
    }

     
    function symbol() public view returns (string _symbol) {
      return lib.getTokenSymbol(address(this));
    }

     
    function tla() public view returns (string _tla) {
      return lib.getTokenTLA(address(this));
    }

     
    function version() public view returns (string _version) {
      return lib.getTokenVersion(address(this));
    }

     
    function decimals() public view returns (uint _decimals) {
      return lib.getTokenDecimals(lib.getTokenSymbol(address(this)));
    }

     
    function totalSupply() public view returns (uint supply) {
      return lib.getTokenSupply(lib.getTokenSymbol(address(this)));
    }

     
    function allowance(address account, address spender) public view returns (uint amount) {
      return lib.getTokenAllowance(lib.getTokenSymbol(address(this)), account, spender);
    }

     
    function balanceOf(address account) public view returns (uint balance) {
      return lib.getTokenBalance(lib.getTokenSymbol(address(this)), account);
    }

     
    function getFeeParams() public view returns (uint bps, uint min, uint max, uint flat, bytes feeMsg, address feeAccount) {
      address feeContract = lib.getFeeContract(address(this));
      return (
        lib.getFeeBPS(feeContract),
        lib.getFeeMin(feeContract),
        lib.getFeeMax(feeContract),
        lib.getFeeFlat(feeContract),
        lib.getFeeMsg(feeContract),
        feeContract
      );
    }

     
    function calculateFees(uint amount) public view returns (uint fees) {
      return lib.calculateFees(lib.getFeeContract(address(this)), amount);
    }

     
    function transfer(address to, uint amount) public notDeprecated returns (bool success) {
       
       
      require(
        lib.transfer(lib.getTokenSymbol(address(this)), to, amount, "0x0"),
        "Error: Unable to transfer funds. Please check your parameters."
      );
      return true;
    }

     
    function transferFrom(address from, address to, uint amount) public notDeprecated returns (bool success) {
       
       
      require(
        lib.transferFrom(lib.getTokenSymbol(address(this)), from, to, amount, "0x0"),
        "Error: Unable to transfer funds. Please check your parameters and ensure the spender has the approved amount of funds to transfer."
      );
      return true;
    }

     
    function approve(address spender, uint amount) public notDeprecated returns (bool success) {
       
       
      require(
        lib.approveAllowance(spender, amount),
        "Error: Unable to approve allowance for spender. Please ensure spender is not null and does not have a frozen balance."
      );
      return true;
    }

     
    function deprecateInterface() public onlyOwner returns (bool deprecated) {
      require(lib.setDeprecatedContract(address(this)),
        "Error: Unable to deprecate contract!");
      return true;
    }

    modifier notDeprecated() {
       
      require(!lib.isContractDeprecated(address(this)),
        "Error: Contract has been deprecated, cannot perform operation!");
      _;
    }

  }