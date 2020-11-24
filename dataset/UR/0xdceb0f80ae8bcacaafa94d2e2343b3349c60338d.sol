 

pragma solidity ^0.4.25;


 
contract BetherERC223Interface {
     
    uint256 public totalSupply;

     
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining);

     
    function approve(address _spender, uint256 _value) public returns (bool _approved);

     
    function balanceOf(address _address) public constant returns (uint256 balance);

     
    function decimals() public constant returns (uint8 _decimals);

     
    function name() public constant returns (string _name);

     
    function symbol() public constant returns (string _symbol);

     
    function transfer(address _to, uint256 _value) public returns (bool _sent);

     
    function transfer(address _to, uint256 _value, bytes _data) public returns (bool _sent);

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool _sent);
}


  

 
contract ERC223ReceivingContract {

     
    function tokenFallback(address _from, uint256 _value, bytes _data) public;
}


 
contract DepositContract is ERC223ReceivingContract {

     
    BalanceManager public balanceManager;

     
    BetherERC223Interface public betherToken;

     
    constructor(address balanceManagerAddress, address betherTokenAddress) public {
        balanceManager = BalanceManager(balanceManagerAddress);
        betherToken = BetherERC223Interface(betherTokenAddress);
    }

     
    function () public payable {
        require(address(balanceManager).send(msg.value));
    }


     
    function tokenFallback(address, uint256 _value, bytes) public {
        require(msg.sender == address(betherToken));
        require(betherToken.transfer(address(balanceManager), _value));
    }
}


 
contract BalanceManager is ERC223ReceivingContract {

     
    BetherERC223Interface public betherToken;

     
    uint256 public betherForEther;

     
    address public adminWallet;

     
    address public operatorWallet;

     
    constructor(address betherTokenAddress, address _adminWallet, address _operatorWallet) public {
        betherToken = BetherERC223Interface(betherTokenAddress);
        adminWallet = _adminWallet;
        operatorWallet = _operatorWallet;
    }



     
     

     
    modifier adminLevel {
        require(msg.sender == adminWallet);
        _;
    }

     
    modifier operatorLevel {
        require(msg.sender == operatorWallet || msg.sender == adminWallet);
        _;
    }
    
     
    function setAdminWallet(address _adminWallet) public adminLevel {
        adminWallet = _adminWallet;
    }

     
    function setOperatorWallet(address _operatorWallet) public adminLevel {
        operatorWallet = _operatorWallet;
    }



     
     

     
    function setBetherForEther(uint256 _betherForEther) public operatorLevel {
        betherForEther = _betherForEther;
    }

     
    event DepositDetected(address depositContractAddress, uint256 amount);
    
     
    function () public payable {
        uint256 etherValue = msg.value;
        require(etherValue > 0);
        uint256 betherValue = etherValue * betherForEther;
        require(betherValue / etherValue == betherForEther);
        emit DepositDetected(msg.sender, betherValue);
    }

     
    function tokenFallback(address _from, uint256 _value, bytes) public {
        require(msg.sender == address(betherToken));
        emit DepositDetected(_from, _value);
    }



     
     

     
    function sendBether(address target, uint256 amount) public operatorLevel {
        require(betherToken.transfer(target, amount));
    }

     
    function sendEther(address target, uint256 amount) public adminLevel {
        require(target.send(amount));
    }



     
     

     
    event NewDepositContract(address depositContractAddress);

     
    function deployNewDepositContracts(uint256 amount) public {
        for (uint256 i = 0; i < amount; i++) {
            address newContractAddress = new DepositContract(address(this), address(betherToken));
            emit NewDepositContract(newContractAddress);
        }
    }

     
}