 

pragma solidity ^0.4.18;

 
 
 
contract DepositWalletInterface {
    function deposit(address _asset, address _from, uint256 amount) public returns (uint);
    function withdraw(address _asset, address _to, uint256 amount) public returns (uint);
}

 
contract Owned {
     
    address public contractOwner;

     
    address public pendingContractOwner;

    function Owned() {
        contractOwner = msg.sender;
    }

     
    modifier onlyContractOwner() {
        if (contractOwner == msg.sender) {
            _;
        }
    }

     
    function destroy() onlyContractOwner {
        suicide(msg.sender);
    }

     
    function changeContractOwnership(address _to) onlyContractOwner() returns(bool) {
        if (_to  == 0x0) {
            return false;
        }

        pendingContractOwner = _to;
        return true;
    }

     
    function claimContractOwnership() returns(bool) {
        if (pendingContractOwner != msg.sender) {
            return false;
        }

        contractOwner = pendingContractOwner;
        delete pendingContractOwner;

        return true;
    }
}

contract ERC20Interface {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed from, address indexed spender, uint256 value);
    string public symbol;

    function totalSupply() constant returns (uint256 supply);
    function balanceOf(address _owner) constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
    function approve(address _spender, uint256 _value) returns (bool success);
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);
}

 
contract Object is Owned {
     
    uint constant OK = 1;
    uint constant OWNED_ACCESS_DENIED_ONLY_CONTRACT_OWNER = 8;

    function withdrawnTokens(address[] tokens, address _to) onlyContractOwner returns(uint) {
        for(uint i=0;i<tokens.length;i++) {
            address token = tokens[i];
            uint balance = ERC20Interface(token).balanceOf(this);
            if(balance != 0)
                ERC20Interface(token).transfer(_to,balance);
        }
        return OK;
    }

    function checkOnlyContractOwner() internal constant returns(uint) {
        if (contractOwner == msg.sender) {
            return OK;
        }

        return OWNED_ACCESS_DENIED_ONLY_CONTRACT_OWNER;
    }
}

contract BaseWallet is Object, DepositWalletInterface {

    uint constant CUSTOMER_WALLET_SCOPE = 60000;
    uint constant CUSTOMER_WALLET_NOT_OK = CUSTOMER_WALLET_SCOPE + 1;

    address public customer;

    modifier onlyCustomer() {
        if (msg.sender != customer) {
            revert();
        }
        _;
    }

    function() public payable {
        revert();
    }

     
     
     
     
     
     
     
     
    function init(address _customer) public onlyContractOwner returns (uint code) {
        require(_customer != 0x0);
        customer = _customer;
        return OK;
    }

     
     
     
     
     
     
    function destroy(address[] tokens) public onlyContractOwner {
        withdrawnTokens(tokens, msg.sender);
        selfdestruct(msg.sender);
    }

     
    function destroy() public onlyContractOwner {
        revert();
    }

     
     
     
     
     
     
     
     
     
    function deposit(address _asset, address _from, uint256 _amount) public onlyCustomer returns (uint) {
        if (!ERC20Interface(_asset).transferFrom(_from, this, _amount)) {
            return CUSTOMER_WALLET_NOT_OK;
        }
        return OK;
    }

     
     
     
     
     
     
     
     
     
    function withdraw(address _asset, address _to, uint256 _amount) public onlyCustomer returns (uint) {
        if (!ERC20Interface(_asset).transfer(_to, _amount)) {
            return CUSTOMER_WALLET_NOT_OK;
        }
        return OK;
    }

     
     
     
     
     
     
     
     
     
    function approve(address _asset, address _to, uint256 _amount) public onlyCustomer returns (uint) {
        if (!ERC20Interface(_asset).approve(_to, _amount)) {
            return CUSTOMER_WALLET_NOT_OK;
        }
        return OK;
    }
}

contract ProfiteroleWallet is BaseWallet {
	
}