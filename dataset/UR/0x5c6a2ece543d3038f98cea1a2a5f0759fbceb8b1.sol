 

pragma solidity ^0.4.24;

 
contract IERC20Token {
     
    function name() public constant returns (string) {}
    function symbol() public constant returns (string) {}
    function decimals() public constant returns (uint8) {}
    function totalSupply() public constant returns (uint256) {}
    function balanceOf(address _owner) public constant returns (uint256) { _owner; }
    function allowance(address _owner, address _spender) public constant returns (uint256) { _owner; _spender; }

    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
}

 
contract Ownable {
    address public owner;
    address public newOwner;

    event OwnerUpdate(address _prevOwner, address _newOwner);

     
    constructor(address _owner) public {
        owner = _owner;
    }

     
    modifier ownerOnly {
        require(msg.sender == owner);
        _;
    }

     
    function transferOwnership(address _newOwner) public ownerOnly {
        require(_newOwner != owner);
        newOwner = _newOwner;
    }

     
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnerUpdate(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

contract BatchTokensTransfer is Ownable {

     
    constructor () public Ownable(msg.sender) {}

    function batchTokensTransfer(IERC20Token _token, address[] _usersWithdrawalAccounts, uint256[] _amounts) 
        public
        ownerOnly()
        {
            require(_usersWithdrawalAccounts.length == _amounts.length);

            for (uint i = 0; i < _usersWithdrawalAccounts.length; i++) {
                if (_usersWithdrawalAccounts[i] != 0x0) {
                    _token.transfer(_usersWithdrawalAccounts[i], _amounts[i]);
                }
            }
        }

    function transferToken(IERC20Token _token, address _userWithdrawalAccount, uint256 _amount)
        public
        ownerOnly()
        {
            require(_userWithdrawalAccount != 0x0 && _amount > 0);
            _token.transfer(_userWithdrawalAccount, _amount);
        }

    function transferAllTokensToOwner(IERC20Token _token)
        public
        ownerOnly()
        {
            uint256 _amount = _token.balanceOf(this);
            _token.transfer(owner, _amount);
        }
}