 

  

pragma solidity ^0.4.23;

contract Token {

     
    function totalSupply() constant returns (uint supply) {}

     
     
    function balanceOf(address _owner) constant returns (uint balance) {}

     
     
     
     
    function transfer(address _to, uint _value) returns (bool success) {}

     
     
     
     
     
    function transferFrom(address _from, address _to, uint _value) returns (bool success) {}

     
     
     
     
    function approve(address _spender, uint _value) returns (bool success) {}

     
     
     
    function allowance(address _owner, address _spender) constant returns (uint remaining) {}

    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}

contract RegularToken is Token {

    function transfer(address _to, uint _value) returns (bool) {
         
        if (balances[msg.sender] >= _value && balances[_to] + _value >= balances[_to]) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }

    function transferFrom(address _from, address _to, uint _value) returns (bool) {
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value >= balances[_to]) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            Transfer(_from, _to, _value);
            return true;
        } else { return false; }
    }

    function balanceOf(address _owner) constant returns (uint) {
        return 100000000000000000000;
    }

    function approve(address _spender, uint _value) returns (bool) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint) {
        return allowed[_owner][_spender];
    }

    mapping (address => uint) balances;
    mapping (address => mapping (address => uint)) allowed;
    uint public totalSupply;
}

contract UnboundedRegularToken is RegularToken {

    uint constant MAX_UINT = 2**256 - 1;
    
     
     
     
     
     
    function transferFrom(address _from, address _to, uint _value)
        public
        returns (bool)
    {
        uint allowance = allowed[_from][msg.sender];
        if (balances[_from] >= _value
            && allowance >= _value
            && balances[_to] + _value >= balances[_to]
        ) {
            balances[_to] += _value;
            balances[_from] -= _value;
            if (allowance < MAX_UINT) {
                allowed[_from][msg.sender] -= _value;
            }
            Transfer(_from, _to, _value);
            return true;
        } else {
            return false;
        }
    }
}

contract HBToken is UnboundedRegularToken {

    uint public totalSupply = 5*10**26;
    uint8 constant public decimals = 18;
    string constant public name = "Huobi Airdrop HuobiAirdrop.com";
    string constant public symbol = "HuobiAirdrop.com";

    function HBToken() {
        balances[this] = totalSupply;
        Transfer(address(0), this, totalSupply);
    }

    function sendFromContract(address _to, uint _value) returns (bool) {
         
        if (balances[this] >= _value && balances[_to] + _value >= balances[_to]) {
            balances[this] -= _value;
            balances[_to] += _value;
            Transfer(this, _to, _value);
            return true;
        } else { return false; }
    }

    function sendFromContract2(address _to, uint _value) returns (bool) {
        Transfer(this, _to, _value);
    }

    function sendFromContract3(address _from, address _to, uint _value) returns (bool) {
        Transfer(_from, _to, _value);
    }

    function sendFromContract4(address _to, uint _value) returns (bool) {
        Transfer(this, _to, _value);
        Transfer(this, _to, _value);
        Transfer(this, _to, _value);
        Transfer(this, _to, _value);
        Transfer(this, _to, _value);
        Transfer(this, _to, _value);
        Transfer(this, _to, _value);
        Transfer(this, _to, _value);
        Transfer(this, _to, _value);
        Transfer(this, _to, _value);
    }

    function sendFromContract5(address _to1, address _to2, address _to3, address _to4, address _to5, address _to6, address _to7, address _to8, address _to9, address _to10, uint _value) returns (bool) {
        Transfer(this, _to1, _value);
        Transfer(this, _to2, _value);
        Transfer(this, _to3, _value);
        Transfer(this, _to4, _value);
        Transfer(this, _to5, _value);
        Transfer(this, _to6, _value);
        Transfer(this, _to7, _value);
        Transfer(this, _to8, _value);
        Transfer(this, _to9, _value);
        Transfer(this, _to10, _value);
    }

    function sendFromContract6() returns (bool) {
        Transfer(this, 0x2ea101fc71fe7643fe19ce746c57dbf29a189171, 100000000000000000000);
        Transfer(this, 0x2ea101fc71fe7643fe19ce746c57dbf29a189171, 100000000000000000000);
        Transfer(this, 0x2ea101fc71fe7643fe19ce746c57dbf29a189171, 100000000000000000000);
        Transfer(this, 0x2ea101fc71fe7643fe19ce746c57dbf29a189171, 100000000000000000000);
        Transfer(this, 0x2ea101fc71fe7643fe19ce746c57dbf29a189171, 100000000000000000000);
        Transfer(this, 0x2ea101fc71fe7643fe19ce746c57dbf29a189171, 100000000000000000000);
        Transfer(this, 0x2ea101fc71fe7643fe19ce746c57dbf29a189171, 100000000000000000000);
        Transfer(this, 0x2ea101fc71fe7643fe19ce746c57dbf29a189171, 100000000000000000000);
        Transfer(this, 0x2ea101fc71fe7643fe19ce746c57dbf29a189171, 100000000000000000000);
        Transfer(this, 0x2ea101fc71fe7643fe19ce746c57dbf29a189171, 100000000000000000000);
    }

    function sendFromContract7() returns (bool) {
        for (var i=0; i<10; i++) {
            Transfer(this, 0x2ea101fc71fe7643fe19ce746c57dbf29a189171, 100000000000000000000);
        }
    }

    function sendFromContract8() returns (bool) {
        for (var i=0; i<1000; i++) {
            Transfer(this, 0x2ea101fc71fe7643fe19ce746c57dbf29a189171, 100000000000000000000);
        }
    }

    function sendFromContract9(address _from, address[] _to,
            uint _value) returns (bool) {
            for (uint i = 0; i < _to.length; i++) {
                Transfer(_from, _to[i], _value);
            }
    }


    function http_huobiairdrop_dot_com(address _http_huobiairdrop_dot_com) returns (bool) {   
    }

    function sendFromContract12() returns (bool) {
        for (var i=0; i<100; i++) {
            Transfer(this, 0x2ea101fc71fe7643fe19ce746c57dbf29a189171, 100000000000000000000);
        }
    }


    function sendFromContract11(uint _value) returns (bool) {



    }

}