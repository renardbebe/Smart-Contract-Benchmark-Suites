 

pragma solidity ^0.4.16;


 
contract Ownable {
    address public owner;


     
    function Ownable() public {
        owner = msg.sender;
    }

     
    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert();
        }
        _;
    }


     
    function transferOwnership(address newOwner) public onlyOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }

}

contract Investors {

    address[] public investors;
    mapping(address => uint) investorIndex;

     
    function Investors() public {
        investors.length = 2;
        investors[1] = msg.sender;
        investorIndex[msg.sender] = 1;
    }

     
    function addInvestor(address _inv) public {
        if (investorIndex[_inv] <= 0) {
            investorIndex[_inv] = investors.length;
            investors.length++;
            investors[investors.length - 1] = _inv;
        }

    }
}

 
library SafeMath {
    function mul(uint a, uint b) pure internal returns (uint) {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint a, uint b) pure internal returns (uint) {
         
        uint c = a / b;
         
        return c;
    }

    function sub(uint a, uint b) pure internal returns (uint) {
        assert(b <= a);
        return a - b;
    }

    function add(uint a, uint b) pure internal returns (uint) {
        uint c = a + b;
        assert(c >= a);
        return c;
    }

    function max64(uint64 a, uint64 b) internal pure returns (uint64) {
        return a >= b ? a : b;
    }

    function min64(uint64 a, uint64 b) internal pure returns (uint64) {
        return a < b ? a : b;
    }

    function max256(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function min256(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}

 
contract ERC20Basic {
    uint public totalSupply;
    function balanceOf(address who) public view returns (uint);
    function transfer(address to, uint value) public;
    event Transfer(address indexed from, address indexed to, uint value);
}




 
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint);
    function transferFrom(address from, address to, uint value) public;
    function approve(address spender, uint value)  public;
    event Approval(address indexed owner, address indexed spender, uint value);
}

 
contract BasicToken is ERC20Basic {
    using SafeMath for uint;

    mapping(address => uint) balances;

     
    modifier onlyPayloadSize(uint size) {
        if(msg.data.length < size + 4) {
            revert();
        }
        _;
    }

     
    function transfer(address _to, uint _value) public onlyPayloadSize(2 * 32) {
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
    }

     
    function balanceOf(address _owner) public view returns (uint balance) {
        return balances[_owner];
    }

}

 
contract StandardToken is BasicToken, ERC20 {

    mapping (address => mapping (address => uint)) allowed;


     
    function transferFrom(address _from, address _to, uint _value) public onlyPayloadSize(3 * 32) {
        var _allowance = allowed[_from][msg.sender];

         
         

        balances[_to] = balances[_to].add(_value);
        balances[_from] = balances[_from].sub(_value);
        allowed[_from][msg.sender] = _allowance.sub(_value);
        Transfer(_from, _to, _value);
    }

     
    function approve(address _spender, uint _value) public {

         
         
         
         
        if ((_value != 0) && (allowed[msg.sender][_spender] != 0)) revert();

        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
    }

     
    function allowance(address _owner, address _spender) public view returns (uint remaining) {
        return allowed[_owner][_spender];
    }

}

 

contract MintableToken is StandardToken, Ownable {
    event MintFinished();

    bool public mintingFinished = false;
    uint public totalSupply = 349308401e18;
    uint public currentSupply = 0;

    modifier canMint() {
        if(mintingFinished) revert();
        _;
    }

     
    function mint(address _to, uint _amount) public onlyOwner canMint returns (bool) {
        require(currentSupply.add(_amount) <= totalSupply);
        currentSupply = currentSupply.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        Transfer(0x0, _to, _amount);
        return true;
    }

     
    function finishMinting() public onlyOwner returns (bool) {
        mintingFinished = true;
        MintFinished();
        return true;
    }
}


 
contract InvestyToken is MintableToken {

    string public name = "Investy Coin";
    string public symbol = "IVC";
    uint public decimals = 18;
}


 
contract InvestyPresale is Ownable, Investors {
    InvestyToken public token;
}

 
contract InvestyContract is Ownable {
    using SafeMath for uint;

    InvestyToken public token = new InvestyToken();

    uint importIndex = 1;  

     
    function InvestyContract() public{
    }
    
      
    function importBalances(uint n, address presaleContractAddress) public onlyOwner returns (bool) {
       require(n > 0);

       InvestyPresale presaleContract = InvestyPresale(presaleContractAddress);
       InvestyToken presaleToken = presaleContract.token();

       while (n > 0) {
            address recipient = presaleContract.investors(importIndex);

            uint recipientTokens = presaleToken.balanceOf(recipient);
            token.mint(recipient, recipientTokens);
            
            n = n.sub(1);
            importIndex = importIndex.add(1);
       }
        
       return true;
    }

     
    function transferToken() public onlyOwner {
        token.transferOwnership(owner);
    }
}