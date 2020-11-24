 

contract META {

    string public name = "Dunaton Metacurrency 3.0";
    uint8 public decimals = 18;
    string public symbol = "META";

    address public _owner;
    address public dev = 0xC96CfB18C39DC02FBa229B6EA698b1AD5576DF4c;
    uint256 public _tokePerEth = 359;

     
    uint256 public weiAmount;
    uint256 incomingValueAsEth;
    uint256 _calcToken;
    uint256 _tokePerWei;

    uint256 public _totalSupply = 21000000 * 1 ether;
    event Transfer(address indexed _from, address indexed _to, uint _value);
     
    mapping (address => uint256) public balances;

    function META() {
        _owner = msg.sender;
        balances[_owner] = 5800000 * 1 ether;     
        Transfer(this, _owner, (5800000 * 1 ether));
        _totalSupply = sub(_totalSupply,balances[_owner]);
    }

    function transfer(address _to, uint _value, bytes _data) public {
         
        require(balances[msg.sender] >= _value);

        uint codeLength;

        assembly {
         
            codeLength := extcodesize(_to)
        }

        balances[msg.sender] = sub(balanceOf(msg.sender), _value);
        balances[_to] = add(balances[_to], _value);

        Transfer(msg.sender, _to, _value);
    }

    function transfer(address _to, uint _value) public {
         
        require(balances[msg.sender] >= _value);

        uint codeLength;

        assembly {
         
            codeLength := extcodesize(_to)
        }

        balances[msg.sender] = sub(balanceOf(msg.sender), _value);
        balances[_to] = add(balances[_to], _value);

        Transfer(msg.sender, _to, _value);
    }

     
    function () payable public {
        require(msg.value > 0);

         
 
        _tokePerWei = _tokePerEth;
        _calcToken = mul(msg.value,_tokePerWei);  

        require(_totalSupply >= _calcToken);
        _totalSupply = sub(_totalSupply, _calcToken);

        balances[msg.sender] = add(balances[msg.sender], _calcToken);

        Transfer(this, msg.sender, _calcToken);
    }

    function changePayRate(uint256 _newRate) public {
        require((msg.sender == _owner) && (_newRate >= 0));
 
        _tokePerEth = _newRate;
    }

    function safeWithdrawal(address _receiver, uint256 _value) public {
        require((msg.sender == _owner));
        uint256 valueAsEth = mul(_value,1 ether);
        require(valueAsEth < this.balance);
        _receiver.send(valueAsEth);
    }

    function balanceOf(address _receiver) public constant returns (uint balance) {
        return balances[_receiver];
    }

    function changeOwner(address _receiver) public {
        require(msg.sender == _owner);
        _owner = _receiver;
    }

    function totalSupply() public constant returns (uint256) {
        return _totalSupply;
    }

    function updateTokenBalance(uint256 newBalance) public {
        require(msg.sender == _owner);
        _totalSupply = add(_totalSupply,newBalance);
    }

     
    function getWeiAmount() public constant returns (uint256) {
        return weiAmount;
    }
    function getIncomingValueAsEth() public constant returns (uint256) {
        return incomingValueAsEth;
    }
    function getCalcToken() public constant returns (uint256) {
        return _calcToken;
    }
    function getTokePerWei() public constant returns (uint256) {
        return _tokePerWei;
    }

    function mul(uint a, uint b) internal pure returns (uint) {
        uint c = a * b;
        require(a == 0 || c / a == b);
        return c;
    }

    function div(uint a, uint b) internal pure returns (uint) {
         
        uint c = a / b;
         
        return c;
    }

    function sub(uint a, uint b) internal pure returns (uint) {
        require(b <= a);
        return a - b;
    }

    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a);
        return c;
    }
}