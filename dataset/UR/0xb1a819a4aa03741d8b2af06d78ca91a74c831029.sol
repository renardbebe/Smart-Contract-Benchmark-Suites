 

pragma solidity ^0.4.19;
library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}
 
 
 
 
contract ERC20Interface {

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    function name() public view returns (string);
    function symbol() public view returns (string);
    function decimals() public view returns (uint8);
    function totalSupply() public view returns (uint256);

    function balanceOf(address _owner) public view returns (uint256 balance);
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);

    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
}

contract ERC20Token is ERC20Interface {

    using SafeMath for uint256;

    string  private tokenName;
    string  private tokenSymbol;
    uint8   private tokenDecimals;
    uint256 internal tokenTotalSupply;
    uint256 public publicReservedToken;
    uint256 public tokenConversionFactor = 10**4;
    mapping(address => uint256) internal balances;

     
    mapping(address => mapping (address => uint256)) internal allowed;


    function ERC20Token(string _name, string _symbol, uint8 _decimals, uint256 _totalSupply,address _publicReserved,uint256 _publicReservedPersentage,address[] boardReserved,uint256[] boardReservedPersentage) public {
        tokenName = _name;
        tokenSymbol = _symbol;
        tokenDecimals = _decimals;
        tokenTotalSupply = _totalSupply;

         
         
        publicReservedToken = _totalSupply.mul(_publicReservedPersentage).div(tokenConversionFactor);
        balances[_publicReserved] = publicReservedToken;

         
        uint256 boardReservedToken = _totalSupply.sub(publicReservedToken);

         
        Transfer(0x0, _publicReserved, publicReservedToken);

         
        uint256 persentageSum = 0;
        for(uint i=0; i<boardReserved.length; i++){
             
            persentageSum = persentageSum.add(boardReservedPersentage[i]);
            require(persentageSum <= 10000);
             
            uint256 token = boardReservedToken.mul(boardReservedPersentage[i]).div(tokenConversionFactor);
            balances[boardReserved[i]] = token;
            Transfer(0x0, boardReserved[i], token);
        }

    }


    function name() public view returns (string) {
        return tokenName;
    }


    function symbol() public view returns (string) {
        return tokenSymbol;
    }


    function decimals() public view returns (uint8) {
        return tokenDecimals;
    }


    function totalSupply() public view returns (uint256) {
        return tokenTotalSupply;
    }

     
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }


    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }


    function transfer(address _to, uint256 _value) public returns (bool success) {
        uint256 fromBalance = balances[msg.sender];
        if (fromBalance < _value) return false;
        if (_value > 0 && msg.sender != _to) {
          balances[msg.sender] = fromBalance.sub(_value);
          balances[_to] = balances[_to].add(_value);
        }
        Transfer(msg.sender, _to, _value);

        return true;
    }

     
     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        
        uint256 spenderAllowance = allowed [_from][msg.sender];
        if (spenderAllowance < _value) return false;
        uint256 fromBalance = balances [_from];
        if (fromBalance < _value) return false;
    
        allowed [_from][msg.sender] = spenderAllowance.sub(_value);
    
        if (_value > 0 && _from != _to) {
          balances [_from] = fromBalance.add(_value);
          balances [_to] = balances[_to].add(_value);
        }

        Transfer(_from, _to, _value);

        return true;
    }

     
     
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;

        Approval(msg.sender, _spender, _value);

        return true;
    }
}

contract Owned {

    address public owner;
    address public proposedOwner = address(0);

    event OwnershipTransferInitiated(address indexed _proposedOwner);
    event OwnershipTransferCompleted(address indexed _newOwner);
    event OwnershipTransferCanceled();


    function Owned() public
    {
        owner = msg.sender;
    }


    modifier onlyOwner() {
        require(isOwner(msg.sender));
        _;
    }


    function isOwner(address _address) public view returns (bool) {
        return (_address == owner);
    }


    function initiateOwnershipTransfer(address _proposedOwner) public onlyOwner returns (bool) {
        require(_proposedOwner != address(0));
        require(_proposedOwner != address(this));
        require(_proposedOwner != owner);

        proposedOwner = _proposedOwner;

        OwnershipTransferInitiated(proposedOwner);

        return true;
    }


    function cancelOwnershipTransfer() public onlyOwner returns (bool) {
         
        if (proposedOwner == address(0)) {
            return true;
        }
         
        proposedOwner = address(0);

        OwnershipTransferCanceled();

        return true;
    }


    function completeOwnershipTransfer() public returns (bool) {

        require(msg.sender == proposedOwner);

        owner = msg.sender;
        proposedOwner = address(0);

        OwnershipTransferCompleted(owner);

        return true;
    }
}

contract FinalizableToken is ERC20Token, Owned {

    using SafeMath for uint256;


     
    address public publicReservedAddress;

     
    mapping(address=>uint) private boardReservedAccount;
    uint256[] public BOARD_RESERVED_YEARS = [1 years,2 years,3 years,4 years,5 years,6 years,7 years,8 years,9 years,10 years];
    
    event Burn(address indexed burner,uint256 value);

     
    function FinalizableToken(string _name, string _symbol, uint8 _decimals, uint256 _totalSupply,address _publicReserved,uint256 _publicReservedPersentage,address[] _boardReserved,uint256[] _boardReservedPersentage) public
    ERC20Token(_name, _symbol, _decimals, _totalSupply, _publicReserved, _publicReservedPersentage, _boardReserved, _boardReservedPersentage)
    Owned(){
        publicReservedAddress = _publicReserved;
        for(uint i=0; i<_boardReserved.length; i++){
            boardReservedAccount[_boardReserved[i]] = currentTime() + BOARD_RESERVED_YEARS[i];
        }
    }


    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(validateTransfer(msg.sender, _to));
        return super.transfer(_to, _value);
    }


    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(validateTransfer(msg.sender, _to));
        return super.transferFrom(_from, _to, _value);
    }


    function validateTransfer(address _sender, address _to) private view returns(bool) {
         
        require(_to != address(0));
        
         
        uint256 time = boardReservedAccount[_sender];
        if (time == 0) {
             
            return true;
        }else{
             
            return currentTime() > time;
        }
    }

     
    function burn(uint256 _value) public {
        require(_value > 0);
        require(_value <= balances[msg.sender]);


        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        tokenTotalSupply = tokenTotalSupply.sub(_value);
        Burn(burner, _value);
    }
    
      
    function currentTime() public constant returns (uint256) {
        return now;
    }

}

contract DOCTokenConfig {

    string  public constant TOKEN_SYMBOL      = "DOC";
    string  public constant TOKEN_NAME        = "DOMUSCOINS Token";
    uint8   public constant TOKEN_DECIMALS    = 18;

    uint256 public constant DECIMALSFACTOR    = 10**uint256(TOKEN_DECIMALS);
    uint256 public constant TOKEN_TOTALSUPPLY = 1000000000 * DECIMALSFACTOR;

    address public constant PUBLIC_RESERVED = 0x347364f2bc343f6c676620d09eb9c37431dbee60;
    uint256 public constant PUBLIC_RESERVED_PERSENTAGE = 9000;

    address[] public BOARD_RESERVED = [0x7a59b7a5d6b00745effe411090ff424819b7055a,
    0x00b9991e08d8e20b6efd12d259321b7ab88a700a,
    0x4826f541eba27b6db07c14a7c2b1a4ea404eca37,
    0xf2baf639dc3f7f05912b8760049094adebc85244,
    0xb64ddc7df18737863eeb613f692595523a0e8d4b,
    0x46c999a445d6ae5d800ce76e90ce06935188b7ab,
    0x46c999a445d6ae5d800ce76e90ce06935188b7ab,
    0x428e8c098453fa9968b712ac59806f91ae202807,
    0x17a58a997a0a5ea218e82c7ae6d560e04f4defa0,
    0x03ff44be1efb207fea4a30fd546b0741a476a0e4];

    uint256[] public BOARD_RESERVED_PERSENTAGE = [200,200,200,500,500,1000,1000,2000,2000,2400];

}

contract DOCToken is FinalizableToken, DOCTokenConfig {

    using SafeMath for uint256;
    event TokensReclaimed(uint256 _amount);

    function DOCToken() public
    FinalizableToken(TOKEN_NAME, TOKEN_SYMBOL, TOKEN_DECIMALS, TOKEN_TOTALSUPPLY, PUBLIC_RESERVED, PUBLIC_RESERVED_PERSENTAGE, BOARD_RESERVED, BOARD_RESERVED_PERSENTAGE)
    {

    }


     
    function reclaimTokens() public onlyOwner returns (bool) {

        address account = address(this);
        uint256 amount  = balanceOf(account);

        if (amount == 0) {
            return false;
        }

        balances[account] = balances[account].sub(amount);
        balances[owner] = balances[owner].add(amount);

        Transfer(account, owner, amount);

        TokensReclaimed(amount);

        return true;
    }
}