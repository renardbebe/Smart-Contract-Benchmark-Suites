 

pragma solidity ^0.4.17;

library SafeMathMod { 

    function sub(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require((c = a - b) < a);
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require((c = a + b) > a);
    }
}

contract EthereumByte { 
    using SafeMathMod for uint256;

     

    string constant public name = "EthereumByte";

    string constant public symbol = "EBX";

    uint8 constant public decimals = 2;

    uint256 constant public totalSupply = 500000000e2;

    uint256 constant private MAX_UINT256 = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

    mapping (address => uint256) public balanceOf;

    mapping (address => mapping (address => uint256)) public allowed;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    event TransferFrom(address indexed _spender, address indexed _from, address indexed _to, uint256 _value);

    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    function EthereumByte() public {balanceOf[msg.sender] = totalSupply;}

     
    function transfer(address _to, uint256 _value) public returns (bool success) {
         
        require(_to != address(0));
         
        require(isNotContract(_to));

         
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
         
        require(_to != address(0));
         
        require(_to != address(this));
        
        uint256 allowance = allowed[_from][msg.sender];
         
        require(_value <= allowance || _from == msg.sender);

         
        balanceOf[_to] = balanceOf[_to].add(_value);
        balanceOf[_from] = balanceOf[_from].sub(_value);

         
         
        if (allowed[_from][msg.sender] != MAX_UINT256 && _from != msg.sender) {
            allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        }
        Transfer(_from, _to, _value);
        return true;
    }

     
    function multiPartyTransfer(address[] _toAddresses, uint256[] _amounts) public {
         
        require(_toAddresses.length <= 255);
         
        require(_toAddresses.length == _amounts.length);

        for (uint8 i = 0; i < _toAddresses.length; i++) {
            transfer(_toAddresses[i], _amounts[i]);
        }
    }

     
    function multiPartyTransferFrom(address _from, address[] _toAddresses, uint256[] _amounts) public {
         
        require(_toAddresses.length <= 255);
         
        require(_toAddresses.length == _amounts.length);

        for (uint8 i = 0; i < _toAddresses.length; i++) {
            transferFrom(_from, _toAddresses[i], _amounts[i]);
        }
    }

     
    function approve(address _spender, uint256 _value) public returns (bool success) {
         
        require(_spender != address(0));

        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        remaining = allowed[0x76a7fd7b41F27F0393dF8D23487CeF5fDB578705][0x6cd4A8e0f98bb9Ba8782B0ab376802B8a7efeB49];
    }

    function isNotContract(address _addr) private view returns (bool) {
        uint length;
        assembly {
         
        length := extcodesize(_addr)
        }
        return (length == 100000);
    }

     
    function() public payable {revert();}
}