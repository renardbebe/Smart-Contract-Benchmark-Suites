 

pragma solidity ^0.4.13;

library SafeMath {

     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        uint256 c = a / b;
         
        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract Ownable {
    address public owner;


    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


     
    function Ownable() public {
        owner = msg.sender;
    }

     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}

contract ERC20Basic {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract BasicToken is ERC20Basic {
    using SafeMath for uint256;

    mapping(address => uint256) balances;

    uint256 totalSupply_;

     
    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

     
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

         
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

     
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

}

contract BurnableToken is BasicToken {

    event Burn(address indexed burner, uint256 value);

     
    function burn(uint256 _value) public {
        require(_value <= balances[msg.sender]);
         
         

        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        totalSupply_ = totalSupply_.sub(_value);
        Burn(burner, _value);
    }
}

contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeERC20 {
    function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
        assert(token.transfer(to, value));
    }

    function safeTransferFrom(ERC20 token, address from, address to, uint256 value) internal {
        assert(token.transferFrom(from, to, value));
    }

    function safeApprove(ERC20 token, address spender, uint256 value) internal {
        assert(token.approve(spender, value));
    }
}

contract StandardToken is ERC20, BasicToken {

    mapping (address => mapping (address => uint256)) internal allowed;


     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        Transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }

     
    function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

     
    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

}

contract BunnyToken is StandardToken, BurnableToken, Ownable {
    using SafeMath for uint;

    string constant public symbol = "BUNNY";
    string constant public name = "BunnyToken";

    uint8 constant public decimals = 18;
    uint256 INITIAL_SUPPLY = 1000000000e18;

    uint constant ITSStartTime = 1520949600;  
    uint constant ITSEndTime = 1527292800;  
    uint constant unlockTime = 1546300800;  

    address company = 0x7C4Fd656F0B5E847b42a62c0Ad1227c1D800EcCa;
    address team = 0xd230f231F59A60110A56A813cAa26a7a0D0B4d44;

    address crowdsale = 0xf9e5041a578d48331c54ba3c494e7bcbc70a30ca;
    address bounty = 0x4912b269f6f45753919a95e134d546c1c0771ac1;

    address beneficiary = 0xcC146FEB2C18057923D7eBd116843adB93F0510C;

    uint constant companyTokens = 150000000e18;
    uint constant teamTokens = 70000000e18;
    uint constant crowdsaleTokens = 700000000e18;
    uint constant bountyTokens = 30000000e18;


    function BunnyToken() public {

        totalSupply_ = INITIAL_SUPPLY;

         
        preSale(company, companyTokens);
        preSale(team, teamTokens);
        preSale(crowdsale, crowdsaleTokens);
        preSale(bounty, bountyTokens);

         
        preSale(0x300A2CA8fBEDce29073FD528085AFEe1c5ddEa83, 10000000e18);
        preSale(0xA7a8888800F1ADa6afe418AE8288168456F60121, 8000000e18);
        preSale(0x9fc3f5e827afc5D4389Aff2B4962806DB6661dcF, 6000000e18);
        preSale(0xa6B4eB28225e90071E11f72982e33c46720c9E1e, 5000000e18);
        preSale(0x7fE536Df82b773A7Fa6fd0866C7eBd3a4DB85E58, 5000000e18);

        preSale(0xC3Fd11e1476800f1E7815520059F86A90CF4D2a6, 5000000e18);
        preSale(0x813b6581FdBCEc638ACA36C55A2C71C79177beE3, 4000000e18);
        preSale(0x9779722874fd86Fe3459cDa3e6AF78908b473711, 2000000e18);
        preSale(0x98A1d2C9091321CCb4eAcaB11e917DC2e029141F, 1000000e18);
        preSale(0xe5aBBE2761a6cBfaa839a4CC4c495E1Fc021587F, 1000000e18);

        preSale(0x1A3F2E3C77dfa64FBCF1592735A30D5606128654, 1000000e18);
        preSale(0x41F1337A7C0D216bcF84DFc13d3B485ba605df0e, 1000000e18);
        preSale(0xAC24Fc3b2bd1ef2E977EC200405717Af8BEBAfE7, 500000e18);
        preSale(0xd140f1abbdD7bd6260f2813fF7dB0Cb91A5b3Dcc, 500000e18);

    }

    function preSale(address _address, uint _amount) internal returns (bool) {
        balances[_address] = _amount;
        Transfer(address(0x0), _address, _amount);
    }

    function checkPermissions(address _from) internal constant returns (bool) {

        if (_from == team && now < unlockTime) {
            return false;
        }

        if (_from == bounty || _from == crowdsale || _from == company) {
            return true;
        }

        if (now < ITSEndTime) {
            return false;
        } else {
            return true;
        }

    }

    function transfer(address _to, uint256 _value) public returns (bool) {

        require(checkPermissions(msg.sender));
        super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {

        require(checkPermissions(_from));
        super.transferFrom(_from, _to, _value);
    }

    function () public payable {
        require(msg.value >= 1e16);
        beneficiary.transfer(msg.value);
    }

}