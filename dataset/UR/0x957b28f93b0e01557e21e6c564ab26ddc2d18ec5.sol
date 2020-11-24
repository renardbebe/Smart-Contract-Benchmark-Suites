 

pragma solidity 0.5.4;


 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
     
     
     
    if (a == 0) {
      return 0;
    }

    c = a * b;
    assert(c / a == b);
    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
    return a / b;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

 

contract MultiOwnable {
    using SafeMath for uint8;

    struct CommitteeStatusPack{
       
        uint8 numOfOwners;
        uint8 numOfVotes;
        uint8 numOfMinOwners;
        bytes proposedFuncData;
    }
    CommitteeStatusPack public committeeStatus;

    address[] public ballot;  
    mapping(address => bool) public owner;

    event Vote(address indexed proposer, bytes indexed proposedFuncData);
    event Propose(address indexed proposer, bytes indexed proposedFuncData);
    event Dismiss(address indexed proposer, bytes indexed proposedFuncData);
    event AddedOwner(address newOwner);
    event RemovedOwner(address removedOwner);
    event TransferOwnership(address from, address to);


     
    constructor(address _coOwner1, address _coOwner2, address _coOwner3, address _coOwner4, address _coOwner5) internal {
        require(_coOwner1 != address(0x0) &&
                _coOwner2 != address(0x0) &&
                _coOwner3 != address(0x0) &&
                _coOwner4 != address(0x0) &&
                _coOwner5 != address(0x0));
        require(_coOwner1 != _coOwner2 &&
                _coOwner1 != _coOwner3 &&
                _coOwner1 != _coOwner4 &&
                _coOwner1 != _coOwner5 &&
                _coOwner2 != _coOwner3 &&
                _coOwner2 != _coOwner4 &&
                _coOwner2 != _coOwner5 &&
                _coOwner3 != _coOwner4 &&
                _coOwner3 != _coOwner5 &&
                _coOwner4 != _coOwner5);  
        owner[_coOwner1] = true;
        owner[_coOwner2] = true;
        owner[_coOwner3] = true;
        owner[_coOwner4] = true;
        owner[_coOwner5] = true;
        committeeStatus.numOfOwners = 5;
        committeeStatus.numOfMinOwners = 5;
        emit AddedOwner(_coOwner1);
        emit AddedOwner(_coOwner2);
        emit AddedOwner(_coOwner3);
        emit AddedOwner(_coOwner4);
        emit AddedOwner(_coOwner5);
    }


    modifier onlyOwner() {
        require(owner[msg.sender]);
        _;
    }

     
    modifier committeeApproved() {
       
      require( keccak256(committeeStatus.proposedFuncData) == keccak256(msg.data) );  

       
      require(committeeStatus.numOfVotes > committeeStatus.numOfOwners.div(2));
      _;
      _dismiss();  
    }


     
    function propose(bytes memory _targetFuncData) onlyOwner public {
       
      require(committeeStatus.numOfVotes == 0);
      require(committeeStatus.proposedFuncData.length == 0);

       
      committeeStatus.proposedFuncData = _targetFuncData;
      emit Propose(msg.sender, _targetFuncData);
    }

     
    function dismiss() onlyOwner public {
      _dismiss();
    }

     

    function _dismiss() internal {
      emit Dismiss(msg.sender, committeeStatus.proposedFuncData);
      committeeStatus.numOfVotes = 0;
      committeeStatus.proposedFuncData = "";
      delete ballot;
    }


     

    function vote() onlyOwner public {
       
      uint length = ballot.length;  
      for(uint i=0; i<length; i++)  
        require(ballot[i] != msg.sender);

       
      require( committeeStatus.proposedFuncData.length != 0 );

       
       
      committeeStatus.numOfVotes++;
      ballot.push(msg.sender);
      emit Vote(msg.sender, committeeStatus.proposedFuncData);
    }


     
    function transferOwnership(address _newOwner) onlyOwner committeeApproved public {
        require( _newOwner != address(0x0) );  
        require( owner[_newOwner] == false );
        owner[msg.sender] = false;
        owner[_newOwner] = true;
        emit TransferOwnership(msg.sender, _newOwner);
    }

     
    function addOwner(address _newOwner) onlyOwner committeeApproved public {
        require( _newOwner != address(0x0) );
        require( owner[_newOwner] != true );
        owner[_newOwner] = true;
        committeeStatus.numOfOwners++;
        emit AddedOwner(_newOwner);
    }

     
    function removeOwner(address _toRemove) onlyOwner committeeApproved public {
        require( _toRemove != address(0x0) );
        require( owner[_toRemove] == true );
        require( committeeStatus.numOfOwners > committeeStatus.numOfMinOwners );  
        owner[_toRemove] = false;
        committeeStatus.numOfOwners--;
        emit RemovedOwner(_toRemove);
    }
}

contract Pausable is MultiOwnable {
    event Pause();
    event Unpause();

    bool internal paused;

    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    modifier whenPaused() {
        require(paused);
        _;
    }

    modifier noReentrancy() {
        require(!paused);
        paused = true;
        _;
        paused = false;
    }

     
    function pause() public onlyOwner committeeApproved whenNotPaused {
        paused = true;
        emit Pause();
    }

    function unpause() public onlyOwner committeeApproved whenPaused {
        paused = false;
        emit Unpause();
    }
}

 
contract RunningContractManager is Pausable {
    address public implementation;  

    event Upgraded(address indexed newContract);

    function upgrade(address _newAddr) onlyOwner committeeApproved external {
        require(implementation != _newAddr);
        implementation = _newAddr;
        emit Upgraded(_newAddr);  
    }

     
}



 
contract TokenERC20 is RunningContractManager {
    using SafeMath for uint256;

     
    string public name;
    string public symbol;
    uint8 public decimals = 18;     
    uint256 public totalSupply;

     
    mapping (address => uint256) internal balances;
    mapping (address => mapping (address => uint256)) internal allowed;
     
    mapping (address => uint256) public frozenExpired;

     
    bool private initialized;  

     


     
    event Transfer(address indexed from, address indexed to, uint256 value);
    event LastBalance(address indexed account, uint256 value);

     
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

     
     

     
     
    event FrozenFunds(address target, uint256 expirationDate);  

     

    function initToken(
        string memory _tokenName,
        string memory _tokenSymbol,
        uint256 _initialSupply,
        address _marketSaleManager,
        address _serviceOperationManager,
        address _dividendManager,
        address _incentiveManager,
        address _reserveFundManager
    ) internal onlyOwner committeeApproved {
        require( initialized == false );
        require(_initialSupply > 0 && _initialSupply <= 2**uint256(184));  

        name = _tokenName;                                        
        symbol = _tokenSymbol;                                    
         

         

         
        uint256 tempSupply = convertToDecimalUnits(_initialSupply);

        uint256 dividendBalance = tempSupply.div(10);                
        uint256 reserveFundBalance = dividendBalance;                
        uint256 marketSaleBalance = tempSupply.div(5);               
        uint256 serviceOperationBalance = marketSaleBalance.mul(2);  
        uint256 incentiveBalance = marketSaleBalance;                

        balances[_marketSaleManager] = marketSaleBalance;
        balances[_serviceOperationManager] = serviceOperationBalance;
        balances[_dividendManager] = dividendBalance;
        balances[_incentiveManager] = incentiveBalance;
        balances[_reserveFundManager] = reserveFundBalance;

        totalSupply = tempSupply;

        emit Transfer(address(0), _marketSaleManager, marketSaleBalance);
        emit Transfer(address(0), _serviceOperationManager, serviceOperationBalance);
        emit Transfer(address(0), _dividendManager, dividendBalance);
        emit Transfer(address(0), _incentiveManager, incentiveBalance);
        emit Transfer(address(0), _reserveFundManager, reserveFundBalance);

        emit LastBalance(address(this), 0);
        emit LastBalance(_marketSaleManager, marketSaleBalance);
        emit LastBalance(_serviceOperationManager, serviceOperationBalance);
        emit LastBalance(_dividendManager, dividendBalance);
        emit LastBalance(_incentiveManager, incentiveBalance);
        emit LastBalance(_reserveFundManager, reserveFundBalance);

        assert( tempSupply ==
          marketSaleBalance.add(serviceOperationBalance).
                            add(dividendBalance).
                            add(incentiveBalance).
                            add(reserveFundBalance)
        );


        initialized = true;
    }


     
    function convertToDecimalUnits(uint256 _value) internal view returns (uint256 value) {
        value = _value.mul(10 ** uint256(decimals));
        return value;
    }

     
    function balanceOf(address _account) public view returns (uint256 balance) {
        balance = balances[_account];
        return balance;
    }

     
    function allowance(address _owner, address _spender) external view returns (uint256 remaining) {
        remaining = allowed[_owner][_spender];
        return remaining;
    }

     
    function _transfer(address _from, address _to, uint256 _value) internal {
        require(_to != address(0x0));                                             
        require(balances[_from] >= _value);                              
        if(frozenExpired[_from] != 0 ){                                  
            require(block.timestamp > frozenExpired[_from]);
            _unfreezeAccount(_from);
        }
        if(frozenExpired[_to] != 0 ){                                    
            require(block.timestamp > frozenExpired[_to]);
            _unfreezeAccount(_to);
        }

        uint256 previousBalances = balances[_from].add(balances[_to]);   

        balances[_from] = balances[_from].sub(_value);                   
        balances[_to] = balances[_to].add(_value);                       
        emit Transfer(_from, _to, _value);
        emit LastBalance(_from, balances[_from]);
        emit LastBalance(_to, balances[_to]);

         
        assert(balances[_from] + balances[_to] == previousBalances);
    }

     
    function transfer(address _to, uint256 _value) public noReentrancy returns (bool success) {
        _transfer(msg.sender, _to, _value);
        success = true;
        return success;
    }


     
    function transferFrom(address _from, address _to, uint256 _value) public noReentrancy returns (bool success) {
        require(_value <= allowed[_from][msg.sender]);      
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        _transfer(_from, _to, _value);
        success = true;
        return success;
    }

     
    function _approve(address _spender, uint256 _value) internal returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        success = true;
        return success;
    }

     
    function approve(address _spender, uint256 _value) public noReentrancy returns (bool success) {
        success = _approve(_spender, _value);
        return success;
    }


     
    function increaseApproval(address _spender, uint256 _addedValue) public returns (bool) {
      allowed[msg.sender][_spender] = (
        allowed[msg.sender][_spender].add(_addedValue));
      emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
      return true;
    }

     
    function decreaseApproval(address _spender, uint256 _subtractedValue) public returns (bool) {
      uint256 oldValue = allowed[msg.sender][_spender];
      if (_subtractedValue >= oldValue) {
        allowed[msg.sender][_spender] = 0;
      } else {
        allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
      }
      emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
      return true;
    }




     
     
    function freezeAccount(address target, uint256 freezeExpiration) onlyOwner committeeApproved public {
        frozenExpired[target] = freezeExpiration;
         
        emit FrozenFunds(target, freezeExpiration);  
    }

     
     
     
     
    function _unfreezeAccount(address target) internal returns (bool success) {
        frozenExpired[target] = 0;
         
        emit FrozenFunds(target, 0);  
        success = true;
        return success;
    }

     
     
    function unfreezeAccount(address target) onlyOwner committeeApproved public returns(bool success) {
        success = _unfreezeAccount(target);
        return success;
    }

}


 

contract TokenExchanger is TokenERC20{
  using SafeMath for uint256;

    uint256 internal tokenPerEth;
    bool public opened;

    event ExchangeEtherToToken(address indexed from, uint256 etherValue, uint256 tokenPerEth);
    event ExchangeTokenToEther(address indexed from, uint256 etherValue, uint256 tokenPerEth);
    event WithdrawToken(address indexed to, uint256 value);
    event WithdrawEther(address indexed to, uint256 value);
    event SetExchangeRate(address indexed from, uint256 tokenPerEth);


    constructor(address _coOwner1,
                address _coOwner2,
                address _coOwner3,
                address _coOwner4,
                address _coOwner5)
        MultiOwnable( _coOwner1, _coOwner2, _coOwner3, _coOwner4, _coOwner5) public { opened = true; }

     
    function initExchanger(
        string calldata _tokenName,
        string calldata _tokenSymbol,
        uint256 _initialSupply,
        uint256 _tokenPerEth,
        address _marketSaleManager,
        address _serviceOperationManager,
        address _dividendManager,
        address _incentiveManager,
        address _reserveFundManager
    ) external onlyOwner committeeApproved {
        require(opened);
         
        require(_tokenPerEth > 0);  
        require(_marketSaleManager != address(0) &&
                _serviceOperationManager != address(0) &&
                _dividendManager != address(0) &&
                _incentiveManager != address(0) &&
                _reserveFundManager != address(0));
        require(_marketSaleManager != _serviceOperationManager &&
                _marketSaleManager != _dividendManager &&
                _marketSaleManager != _incentiveManager &&
                _marketSaleManager != _reserveFundManager &&
                _serviceOperationManager != _dividendManager &&
                _serviceOperationManager != _incentiveManager &&
                _serviceOperationManager != _reserveFundManager &&
                _dividendManager != _incentiveManager &&
                _dividendManager != _reserveFundManager &&
                _incentiveManager != _reserveFundManager);  

        super.initToken(_tokenName, _tokenSymbol, _initialSupply,
           
          _marketSaleManager,
          _serviceOperationManager,
          _dividendManager,
          _incentiveManager,
          _reserveFundManager
        );
        tokenPerEth = _tokenPerEth;
        emit SetExchangeRate(msg.sender, tokenPerEth);
    }


     
    function setExchangeRate(uint256 _tokenPerEth) onlyOwner committeeApproved external returns (bool success){
        require(opened);
        require( _tokenPerEth > 0);
        tokenPerEth = _tokenPerEth;
        emit SetExchangeRate(msg.sender, tokenPerEth);

        success = true;
        return success;
    }

    function getExchangerRate() external view returns(uint256){
        return tokenPerEth;
    }

     
    function exchangeEtherToToken() payable external noReentrancy returns (bool success){
        require(opened);
        uint256 tokenPayment;
        uint256 ethAmount = msg.value;

        require(ethAmount > 0);
        require(tokenPerEth != 0);
        tokenPayment = ethAmount.mul(tokenPerEth);

        super._transfer(address(this), msg.sender, tokenPayment);

        emit ExchangeEtherToToken(msg.sender, msg.value, tokenPerEth);

        success = true;
        return success;
    }

     
    function exchangeTokenToEther(uint256 _value) external noReentrancy returns (bool success){
      require(opened);
      require(tokenPerEth != 0);

      uint256 remainingEthBalance = address(this).balance;
      uint256 etherPayment = _value.div(tokenPerEth);
      uint256 remainder = _value % tokenPerEth;  
      require(remainingEthBalance >= etherPayment);

      uint256 tokenAmount = _value.sub(remainder);  
      super._transfer(msg.sender, address(this), tokenAmount);  
       
      address(msg.sender).transfer(etherPayment);  

      emit ExchangeTokenToEther(address(this), etherPayment, tokenPerEth);
      success = true;
      return success;
    }

     
    function withdrawToken(address _recipient, uint256 _value) onlyOwner committeeApproved noReentrancy public {
       
      super._transfer(address(this) ,_recipient, _value);
      emit WithdrawToken(_recipient, _value);
    }


     
    function withdrawEther(address payable _recipient, uint256 _value) onlyOwner committeeApproved noReentrancy public {
         
         
        _recipient.transfer(_value);  
        emit WithdrawEther(_recipient, _value);
    }

     
    function closeExchanger() onlyOwner committeeApproved external {
        opened = false;
    }
}


 

contract NemodaxStorage is RunningContractManager {

     
     
    string public name;
    string public symbol;
    uint8 public decimals = 18;     
    uint256 public totalSupply;

     
    mapping (address => uint256) internal balances;
    mapping (address => mapping (address => uint256)) internal allowed;
    mapping (address => uint256) public frozenExpired;  

    bool private initialized;

    uint256 internal tokenPerEth;
    bool public opened = true;
}

 

contract ProxyNemodax is NemodaxStorage {

     
    constructor(address _coOwner1,
                address _coOwner2,
                address _coOwner3,
                address _coOwner4,
                address _coOwner5)
        MultiOwnable( _coOwner1, _coOwner2, _coOwner3, _coOwner4, _coOwner5) public {}

    function () payable external {
        address localImpl = implementation;
        require(localImpl != address(0x0));

        assembly {
            let ptr := mload(0x40)

            switch calldatasize
            case 0 {  }  

            default{
                calldatacopy(ptr, 0, calldatasize)

                let result := delegatecall(gas, localImpl, ptr, calldatasize, 0, 0)
                let size := returndatasize
                returndatacopy(ptr, 0, size)
                switch result

                case 0 { revert(ptr, size) }
                default { return(ptr, size) }
            }
        }
    }
}