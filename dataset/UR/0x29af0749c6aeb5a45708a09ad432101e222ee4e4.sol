 

pragma solidity ^0.4.24;

 
contract SMILE {

     

    string constant public name = "Smile Token";
    string constant public symbol = "SMILE";
    uint256 constant public decimals = 18;
    uint256 constant public totalSupply = 100000000 * (10 ** decimals);

     

    address public creator;

     

    bool public distributionFinished = false;

     

    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

     

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Mint(address indexed to, uint value);

     

    modifier canWithdraw(address _tokenAddress) {
        assert(msg.sender == creator && _tokenAddress != address(this));
        _;
    }

     

    modifier canDistribute() {
        assert(msg.sender == creator && !distributionFinished);
        _;
    }

     

    constructor() public {
        creator = msg.sender;
        balanceOf[msg.sender] = totalSupply;
        emit Mint(msg.sender, totalSupply);
    }

     

    function safeSub(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
        assert((c = _a - _b) <= _a);
    }

     

    function safeMul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
         
        assert((c = _a * _b) / _a == _b);
    }

     

    function transfer(address _to, uint256 _value) public returns (bool) {
         
        assert(_to != 0x0);
        bytes memory empty;
        if (isContract(_to)) {
            return transferToContract(_to, _value, empty);
        } else {
            return transferToAddress(_to, _value);
        }
    }

     

    function transfer(address _to, uint256 _value, bytes _data) public returns (bool) {
         
        assert(_to != 0x0);
        if (isContract(_to)) {
            return transferToContract(_to, _value, _data);
        } else {
            return transferToAddress(_to, _value);
        }
    }

     

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        allowance[_from][_to] = safeSub(allowance[_from][_to], _value);
        balanceOf[_from] = safeSub(balanceOf[_from], _value);
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
        return true;
    }

     

    function approve(address _spender, uint256 _value) public returns (bool) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

     

    function transferToContract(address _to, uint256 _value, bytes _data) private returns (bool) {
        balanceOf[msg.sender] = safeSub(balanceOf[msg.sender], _value);
        balanceOf[_to] += _value;
        SMILE interfaceProvider = SMILE(_to);
        interfaceProvider.tokenFallback(msg.sender, _value, _data);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

     

    function tokenFallback(address _from, uint256 _value, bytes _data) public {}

     

    function transferToAddress(address _to, uint256 _value) private returns (bool) {
        balanceOf[msg.sender] = safeSub(balanceOf[msg.sender], _value);
        balanceOf[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

     

    function isContract(address _addr) private view returns (bool) {
        uint256 length;
        assembly {
            length := extcodesize(_addr)
        }
         
        return (length != 0);
    }

     

    function distributeSMILE(address[] _addresses, uint256 _value) canDistribute external {
         for (uint256 i = 0; i < _addresses.length; i++) {
             balanceOf[_addresses[i]] += _value;
             emit Transfer(msg.sender, _addresses[i], _value);
         }
          
         balanceOf[msg.sender] = safeSub(balanceOf[msg.sender], safeMul(_value, _addresses.length));
    }

     

    function retrieveERC(address _token) external canWithdraw(_token) {
        SMILE interfaceProvider = SMILE(_token);
         
        interfaceProvider.transfer(msg.sender, interfaceProvider.balanceOf(address(this)));
    }

     

    function() public {}
}