 

pragma solidity ^0.4.13;


 
contract AbstractToken {

    function totalSupply() constant returns (uint256) {}
    function balanceOf(address owner) constant returns (uint256 balance);
    function transfer(address to, uint256 value) returns (bool success);
    function transferFrom(address from, address to, uint256 value) returns (bool success);
    function approve(address spender, uint256 value) returns (bool success);
    function allowance(address owner, address spender) constant returns (uint256 remaining);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Issuance(address indexed to, uint256 value);
}


contract Owned {

    address public owner = msg.sender;
    address public potentialOwner;

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    modifier onlyPotentialOwner {
        require(msg.sender == potentialOwner);
        _;
    }

    event NewOwner(address old, address current);
    event NewPotentialOwner(address old, address potential);

    function setOwner(address _new)
        public
        onlyOwner
    {
        NewPotentialOwner(owner, _new);
        potentialOwner = _new;
    }

    function confirmOwnership()
        public
        onlyPotentialOwner
    {
        NewOwner(owner, potentialOwner);
        owner = potentialOwner;
        potentialOwner = 0;
    }
}


 
contract StandardToken is AbstractToken, Owned {

     
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    uint256 public totalSupply;

     
     
     
     
    function transfer(address _to, uint256 _value) returns (bool success) {
        if (balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        }
        else {
            return false;
        }
    }

     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
      if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            Transfer(_from, _to, _value);
            return true;
        }
        else {
            return false;
        }
    }

     
     
    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

     
     
     
    function approve(address _spender, uint256 _value) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

     
     
     
     
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

}


 
 
contract SafeMath {
    function mul(uint a, uint b) internal returns (uint) {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint a, uint b) internal returns (uint) {
        assert(b > 0);
        uint c = a / b;
        assert(a == b * c + a % b);
        return c;
    }

    function sub(uint a, uint b) internal returns (uint) {
        assert(b <= a);
        return a - b;
    }

    function add(uint a, uint b) internal returns (uint) {
        uint c = a + b;
        assert(c >= a);
        return c;
    }

    function pow(uint a, uint b) internal returns (uint) {
        uint c = a ** b;
        assert(c >= a);
        return c;
    }
}


 
 
contract Token is StandardToken, SafeMath {

     
    uint public creationTime;

    function Token() {
        creationTime = now;
    }


     
    function transferERC20Token(address tokenAddress)
        public
        onlyOwner
        returns (bool)
    {
        uint balance = AbstractToken(tokenAddress).balanceOf(this);
        return AbstractToken(tokenAddress).transfer(owner, balance);
    }

     
    function withDecimals(uint number, uint decimals)
        internal
        returns (uint)
    {
        return mul(number, pow(10, decimals));
    }
}


 
 
contract TokenboxToken is Token {

     
    string constant public name = "Tokenbox";
     
    string constant public symbol = "TBX";
    uint8 constant public decimals = 18;

     
    address constant public foundationReserve = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

     
    address constant public icoAllocation = 0x1111111111111111111111111111111111111111;

     
    address constant public preIcoAllocation = 0x2222222222222222222222222222222222222222;

     
    uint256 constant public startDate = 1510660800;
     
    uint256 constant public duration = 14 days;

     
    uint256 constant public vestingDateEnd = 1543406400;

     
    uint256 public totalPicoUSD = 0;
    uint8 constant public usdDecimals = 12;

     
    address public signer;

     
    address public multisig;

    bool public finalised = false;

     
    event InvestmentInETH(address investor, uint256 tokenPriceInWei, uint256 investedInWei, uint256 investedInPicoUsd, uint256 tokensNumber, bytes32 hash);
    event InvestmentInBTC(address investor, uint256 tokenPriceInSatoshi, uint256 investedInSatoshi, uint256 investedInPicoUsd, uint256 tokensNumber, string btcAddress);
    event InvestmentInUSD(address investor, uint256 tokenPriceInPicoUsd, uint256 investedInPicoUsd, uint256 tokensNumber);
    event PresaleInvestment(address investor, uint256 investedInPicoUsd, uint256 tokensNumber);

     
    function TokenboxToken(address _signer, address _multisig, uint256 _preIcoTokens )
    {
         
        totalSupply = withDecimals(31000000, decimals);

        uint preIcoTokens = withDecimals(_preIcoTokens, decimals);

         
        balances[preIcoAllocation] = preIcoTokens;

         
        balances[foundationReserve] = 0;

         
        balances[icoAllocation] = div(mul(totalSupply, 75), 100)  - preIcoTokens;

        signer = _signer;
        multisig = _multisig;
    }

    modifier icoIsActive {
        require(now >= startDate && now < startDate + duration);
        _;
    }

    modifier icoIsCompleted {
        require(now >= startDate + duration);
        _;
    }

    modifier onlyOwnerOrSigner {
        require((msg.sender == owner) || (msg.sender == signer));
        _;
    }

     
    function invest(address investor, uint256 tokenPriceInPicoUsd, uint256 investedInWei, bytes32 hash, uint8 v, bytes32 r, bytes32 s, uint256 WeiToUSD)
        public
        icoIsActive
        payable
    {
         
        require(sha256(uint(investor) << 96 | tokenPriceInPicoUsd) == hash);

         
        require(ecrecover(hash, v, r, s) == signer);

         
         
        require(sub(investedInWei, msg.value) <= withDecimals(5, 15));

        uint tokenPriceInWei = div(mul(tokenPriceInPicoUsd, WeiToUSD), pow(10, usdDecimals));

         
        uint256 tokensNumber = div(withDecimals(investedInWei, decimals), tokenPriceInWei);

         
        require(balances[icoAllocation] >= tokensNumber);

         
        require(multisig.send(msg.value));

        uint256 investedInPicoUsd = div(withDecimals(investedInWei, usdDecimals), WeiToUSD);

        investInUSD(investor, investedInPicoUsd, tokensNumber);

        InvestmentInETH(investor, tokenPriceInWei, investedInWei, investedInPicoUsd, tokensNumber, hash);
    }

     
    function investInBTC(address investor, uint256 tokenPriceInPicoUsd, uint256 investedInSatoshi, string btcAddress, uint256 satoshiToUSD)
        public
        icoIsActive
        onlyOwnerOrSigner
    {
        uint tokenPriceInSatoshi = div(mul(tokenPriceInPicoUsd, satoshiToUSD), pow(10, usdDecimals));

         
        uint256 tokensNumber = div(withDecimals(investedInSatoshi, decimals), tokenPriceInSatoshi);

         
        require(balances[icoAllocation] >= tokensNumber);

        uint256 investedInPicoUsd = div(withDecimals(investedInSatoshi, usdDecimals), satoshiToUSD);

        investInUSD(investor, investedInPicoUsd, tokensNumber);

        InvestmentInBTC(investor, tokenPriceInSatoshi, investedInSatoshi, investedInPicoUsd, tokensNumber, btcAddress);
    }

     
    function investInUSD(address investor, uint256 investedInPicoUsd, uint256 tokensNumber)
        private
    {
      totalPicoUSD = add(totalPicoUSD, investedInPicoUsd);

       
      balances[icoAllocation] -= tokensNumber;
      balances[investor] += tokensNumber;
      Transfer(icoAllocation, investor, tokensNumber);
    }

     
    function wireInvestInUSD(address investor, uint256 tokenPriceInUsdCents, uint256 investedInUsdCents)
        public
        icoIsActive
        onlyOwnerOrSigner
     {

       uint256 tokensNumber = div(withDecimals(investedInUsdCents, decimals), tokenPriceInUsdCents);

        
       require(balances[icoAllocation] >= tokensNumber);

        
       uint256 investedInPicoUsd = withDecimals(investedInUsdCents, usdDecimals - 2);
       uint256 tokenPriceInPicoUsd = withDecimals(tokenPriceInUsdCents, usdDecimals - 2);

       investInUSD(investor, investedInPicoUsd, tokensNumber);

       InvestmentInUSD(investor, tokenPriceInPicoUsd, investedInPicoUsd, tokensNumber);
    }

     
    function preIcoDistribution(address investor, uint256 investedInUsdCents, uint256 tokensNumber)
        public
        onlyOwner
    {
      uint256 tokensNumberWithDecimals = withDecimals(tokensNumber, decimals);

       
      require(balances[preIcoAllocation] >= tokensNumberWithDecimals);

       
      balances[preIcoAllocation] -= tokensNumberWithDecimals;
      balances[investor] += tokensNumberWithDecimals;
      Transfer(preIcoAllocation, investor, tokensNumberWithDecimals);

      uint256 investedInPicoUsd = withDecimals(investedInUsdCents, usdDecimals - 2);
       
      totalPicoUSD = add(totalPicoUSD, investedInPicoUsd);

      PresaleInvestment(investor, investedInPicoUsd, tokensNumberWithDecimals);
    }


     
    function allowToWithdrawFromReserve()
        public
        onlyOwner
    {
        require(now >= vestingDateEnd);

         
        allowed[foundationReserve][msg.sender] = balanceOf(foundationReserve);
    }


     
    function withdrawFromReserve(uint amount)
        public
        onlyOwner
    {
        require(now >= vestingDateEnd);
         
        require(transferFrom(foundationReserve, multisig, amount));
    }

     
    function changeMultisig(address _multisig)
        public
        onlyOwner
    {
        multisig = _multisig;
    }

     
    function changeSigner(address _signer)
        public
        onlyOwner
    {
        signer = _signer;
    }

     
     
    function finaliseICO()
        public
        onlyOwner
        icoIsCompleted
    {
        require(!finalised);

         
        totalSupply = sub(totalSupply, balanceOf(icoAllocation));
        totalSupply = sub(totalSupply, withDecimals(7750000, decimals));

         
        balances[multisig] = div(mul(totalSupply, 125), 1000);

         
        balances[foundationReserve] = div(mul(totalSupply, 125), 1000);

        totalSupply = add(totalSupply, mul(balanceOf(foundationReserve), 2));

         
        balances[icoAllocation] = 0;

        finalised = true;
    }

    function totalUSD()
      public
      constant
      returns (uint)
    {
       return div(totalPicoUSD, pow(10, usdDecimals));
    }
}