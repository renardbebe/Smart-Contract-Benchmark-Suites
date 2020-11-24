 

 

pragma solidity ^0.4.24;


contract Havven {
    uint public price;
    uint public issuanceRatio;
    mapping(address => uint) public nominsIssued;
    function balanceOf(address account) public view returns (uint);
    function totalSupply() public view returns (uint);
    function availableHavvens(address account) public view returns (uint);
}

contract Nomin {
    function totalSupply() public view returns (uint);
}

contract HavvenEscrow {
    function balanceOf(address account) public view returns (uint);
}

 
contract SafeDecimalMath {

     
    uint8 public constant decimals = 18;

     
    uint public constant UNIT = 10 ** uint(decimals);

     
    function addIsSafe(uint x, uint y)
        pure
        internal
        returns (bool)
    {
        return x + y >= y;
    }

     
    function safeAdd(uint x, uint y)
        pure
        internal
        returns (uint)
    {
        require(x + y >= y);
        return x + y;
    }

     
    function subIsSafe(uint x, uint y)
        pure
        internal
        returns (bool)
    {
        return y <= x;
    }

     
    function safeSub(uint x, uint y)
        pure
        internal
        returns (uint)
    {
        require(y <= x);
        return x - y;
    }

     
    function mulIsSafe(uint x, uint y)
        pure
        internal
        returns (bool)
    {
        if (x == 0) {
            return true;
        }
        return (x * y) / x == y;
    }

     
    function safeMul(uint x, uint y)
        pure
        internal
        returns (uint)
    {
        if (x == 0) {
            return 0;
        }
        uint p = x * y;
        require(p / x == y);
        return p;
    }

     
    function safeMul_dec(uint x, uint y)
        pure
        internal
        returns (uint)
    {
         
        return safeMul(x, y) / UNIT;

    }

     
    function divIsSafe(uint x, uint y)
        pure
        internal
        returns (bool)
    {
        return y != 0;
    }

     
    function safeDiv(uint x, uint y)
        pure
        internal
        returns (uint)
    {
         
        require(y != 0);
        return x / y;
    }

     
    function safeDiv_dec(uint x, uint y)
        pure
        internal
        returns (uint)
    {
         
        return safeDiv(safeMul(x, UNIT), y);
    }

     
    function intToDec(uint i)
        pure
        internal
        returns (uint)
    {
        return safeMul(i, UNIT);
    }

    function min(uint a, uint b) 
        pure
        internal
        returns (uint)
    {
        return a < b ? a : b;
    }

    function max(uint a, uint b) 
        pure
        internal
        returns (uint)
    {
        return a > b ? a : b;
    }
}

 
contract Owned {
    address public owner;
    address public nominatedOwner;

     
    constructor(address _owner)
        public
    {
        require(_owner != address(0));
        owner = _owner;
        emit OwnerChanged(address(0), _owner);
    }

     
    function nominateNewOwner(address _owner)
        external
        onlyOwner
    {
        nominatedOwner = _owner;
        emit OwnerNominated(_owner);
    }

     
    function acceptOwnership()
        external
        onlyNominatedOwner
    {
        owner = nominatedOwner;
        nominatedOwner = address(0);
        emit OwnerChanged(owner, nominatedOwner);
    }

    modifier onlyOwner
    {
        require(msg.sender == owner);
        _;
    }

    modifier onlyNominatedOwner
    {
        require(msg.sender == nominatedOwner);
        _;
    }

    event OwnerNominated(address newOwner);
    event OwnerChanged(address oldOwner, address newOwner);
}


 
contract CollateralMonitor is Owned, SafeDecimalMath {
    
    Havven havven;
    Nomin nomin;
    HavvenEscrow escrow;

    address[] issuers;
    uint maxIssuers = 10;

    constructor(Havven _havven, Nomin _nomin, HavvenEscrow _escrow)
        Owned(msg.sender)
        public
    {
        havven = _havven;
        nomin = _nomin;
        escrow = _escrow;
    }

    function setHavven(Havven _havven)
        onlyOwner
        external
    {
        havven = _havven;
    }

    function setNomin(Nomin _nomin)
         onlyOwner
         external
    {
        nomin = _nomin;
    }

    function setEscrow(HavvenEscrow _escrow)
        onlyOwner
        external
    {
        escrow = _escrow;
    }

    function setMaxIssuers(uint newMax)
        onlyOwner
        external
    {
        maxIssuers = newMax;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    modifier onlyNominatedOwner {
        require(msg.sender == nominatedOwner);
        _;
    }

    function pushIssuer(address issuer)
        onlyOwner
        public
    {
        for (uint i = 0; i < issuers.length; i++) {
            require(issuers[i] != issuer);
        }
        issuers.push(issuer);
    }

    function pushIssuers(address[] newIssuers)
        onlyOwner
        external
    {
        for (uint i = 0; i < issuers.length; i++) {
            pushIssuer(newIssuers[i]);
        }
    }

    function deleteIssuer(uint index)
        onlyOwner
        external
    {
        uint length = issuers.length;
        require(index < length);
        issuers[index] = issuers[length - 1];
        delete issuers[length - 1];
    }

    function resizeIssuersArray(uint size)
        onlyOwner
        external
    {
        issuers.length = size;
    }


     

    function collateral(address account)
        public
        view
        returns (uint)
    {
        return safeAdd(havven.balanceOf(account), escrow.balanceOf(account));
    }


     

    function _limitedTotalIssuingCollateral(uint sumLimit)
        internal
        view
        returns (uint)
    {
        uint sum;
        uint limit = min(sumLimit, issuers.length);
        for (uint i = 0; i < limit; i++) {
            sum += collateral(issuers[i]);
        } 
        return sum;
    }

    function totalIssuingCollateral()
        public
        view
        returns (uint)
    {
        return _limitedTotalIssuingCollateral(issuers.length);
    }

    function totalIssuingCollateral_limitedSum()
        public
        view
        returns (uint)
    {
        return _limitedTotalIssuingCollateral(maxIssuers);
    } 



     

    function collateralisation(address account)
        public
        view
        returns (uint)
    {
        safeDiv_dec(safeMul_dec(collateral(account), havven.price()), 
                    havven.nominsIssued(account));
    }


     

    function totalIssuerCollateralisation()
        public
        view
        returns (uint)
    {
        safeDiv_dec(safeMul_dec(totalIssuingCollateral(), havven.price()),
                    nomin.totalSupply());
    }


     

    function totalNetworkCollateralisation()
        public
        view
        returns (uint)
    {
        safeDiv_dec(safeMul_dec(havven.totalSupply(), havven.price()),
                    nomin.totalSupply());
    }


     

    function totalIssuanceDebt()
        public
        view
        returns (uint)
    {
        return safeDiv_dec(nomin.totalSupply(),
                           safeMul_dec(havven.issuanceRatio(), havven.price()));
    }

    function totalIssuanceDebt_limitedSum()
        public
        view
        returns (uint)
    {
        uint sum;
        uint limit = min(maxIssuers, issuers.length);
        for (uint i = 0; i < limit; i++) {
            sum += havven.nominsIssued(issuers[i]);
        }
        return safeDiv_dec(sum,
                           safeMul_dec(havven.issuanceRatio(), havven.price()));
    }


     

    function totalLockedHavvens()
        public
        view
        returns (uint)
    {
        return min(totalIssuanceDebt(), totalIssuingCollateral());
    }

    function totalLockedHavvens_limitedSum()
        public
        view
        returns (uint)
    { 
        return min(totalIssuanceDebt_limitedSum(), totalIssuingCollateral());
    }


     

    function totalLockedHavvens_byAvailableHavvens_limitedSum()
        public
        view
        returns (uint)
    {
        uint sum;
        uint limit = min(maxIssuers, issuers.length);
        for (uint i = 0; i < limit; i++) {
            address issuer = issuers[i];
            sum += safeSub(collateral(issuer), havven.availableHavvens(issuer));
        }
        return sum;
    }
}