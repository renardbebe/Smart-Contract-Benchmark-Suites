 

pragma solidity ^0.5.2;

 

interface DutchX {

    function approvedTokens(address)
        external
        view
        returns (bool);

    function getAuctionIndex(
        address token1,
        address token2
    )
        external
        view
        returns (uint auctionIndex);

    function getClearingTime(
        address token1,
        address token2,
        uint auctionIndex
    )
        external
        view
        returns (uint time);

    function getPriceInPastAuction(
        address token1,
        address token2,
        uint auctionIndex
    )
        external
        view
         
        returns (uint num, uint den);
}

 

 
 

contract DutchXPriceOracle {

    DutchX public dutchX;
    address public ethToken;
    
     
     
     
    constructor(DutchX _dutchX, address _ethToken)
        public
    {
        dutchX = _dutchX;
        ethToken = _ethToken;
    }

     
     
     
     
    function getPrice(address token)
        public
        view
        returns (uint num, uint den)
    {
        (num, den) = getPriceCustom(token, 0, true, 4.5 days, 9);
    }

     
     
     
     
     
     
     
     
    function getPriceCustom(
        address token,
        uint time,
        bool requireWhitelisted,
        uint maximumTimePeriod,
        uint numberOfAuctions
    )
        public
        view
        returns (uint num, uint den)
    {
         
        if (requireWhitelisted && !isWhitelisted(token)) {
            return (0, 0);
        }

        address ethTokenMem = ethToken;

        uint auctionIndex;
        uint latestAuctionIndex = dutchX.getAuctionIndex(token, ethTokenMem);

        if (time == 0) {
            auctionIndex = latestAuctionIndex;
            time = now;
        } else {
             
             
            auctionIndex = computeAuctionIndex(token, 1, 
                latestAuctionIndex - 1, latestAuctionIndex - 1, time) + 1;
        }

         
        uint clearingTime = dutchX.getClearingTime(token, ethTokenMem, auctionIndex - numberOfAuctions - 1);

        if (time - clearingTime > maximumTimePeriod) {
            return (0, 0);
        } else {
            (num, den) = getPricesAndMedian(token, numberOfAuctions, auctionIndex);
        }
    }

     
     
     
     
     
     
     
    function getPricesAndMedian(
        address token,
        uint numberOfAuctions,
        uint auctionIndex
    )
        public
        view
        returns (uint, uint)
    {
         
         
         
         
         
         
         

        uint[] memory nums = new uint[](numberOfAuctions);
        uint[] memory dens = new uint[](numberOfAuctions);
        uint[] memory linkedListOfIndices = new uint[](numberOfAuctions);
        uint indexOfSmallest;

        for (uint i = 0; i < numberOfAuctions; i++) {
             
             
            (uint num, uint den) = dutchX.getPriceInPastAuction(token, ethToken, auctionIndex - 1 - i);

            (nums[i], dens[i]) = (num, den);

             
             
            uint previousIndex;
            uint index = linkedListOfIndices[indexOfSmallest];

            for (uint j = 0; j < i; j++) {
                if (isSmaller(num, den, nums[index], dens[index])) {

                     
                    linkedListOfIndices[i] = index;

                    if (j == 0) {
                         
                        linkedListOfIndices[indexOfSmallest] = i;
                    } else {
                         
                         
                        linkedListOfIndices[previousIndex] = i;
                    }

                    break;
                }

                if (j == i - 1) {
                     
                    linkedListOfIndices[i] = linkedListOfIndices[indexOfSmallest];
                    linkedListOfIndices[index] = i;
                    indexOfSmallest = i;
                } else {
                     
                    previousIndex = index;
                    index = linkedListOfIndices[index];
                }
            }
        }

         

        uint index = indexOfSmallest;

         
        for (uint i = 0; i < (numberOfAuctions + 1) / 2; i++) {
            index = linkedListOfIndices[index];
        }

         
         
         
         
         
         
         
         

        return (nums[index], dens[index]);
    }

     
     
     
     
     
     
     
    function computeAuctionIndex(
        address token,
        uint lowerBound, 
        uint initialUpperBound,
        uint upperBound,
        uint time
    )
        public
        view
        returns (uint)
    {
         
         
         
         

        uint clearingTime;

        if (upperBound - lowerBound == 1) {
             

            if (lowerBound <= 1) {
                clearingTime = dutchX.getClearingTime(token, ethToken, lowerBound); 

                if (time < clearingTime) {
                    revert("time too small");
                }
            }

            if (upperBound == initialUpperBound) {
                clearingTime = dutchX.getClearingTime(token, ethToken, upperBound);

                if (time < clearingTime) {
                    return lowerBound;
                } else {
                     
                    return upperBound;
                }            
            } else {
                 
                return lowerBound;
            }
        }

        uint mid = (lowerBound + upperBound) / 2;
        clearingTime = dutchX.getClearingTime(token, ethToken, mid);

        if (time < clearingTime) {
             
            return computeAuctionIndex(token, lowerBound, initialUpperBound, mid, time);
        } else if (time == clearingTime) {
             
            return mid;
        } else {
             
            return computeAuctionIndex(token, mid, initialUpperBound, upperBound, time);
        }
    }

     
     
     
     
     
     
    function isSmaller(uint num1, uint den1, uint num2, uint den2)
        public
        pure
        returns (bool)
    {
         
        require(den1 != 0, "undefined fraction");
        require(den2 != 0, "undefined fraction");
        require(num1 * den2 / den2 == num1, "overflow");
        require(num2 * den1 / den1 == num2, "overflow");

        return (num1 * den2 < num2 * den1);
    }

     
     
     
    function isWhitelisted(address token) 
        public
        view
        returns (bool) 
    {
        return dutchX.approvedTokens(token);
    }
}

 

contract AuctioneerManaged {
     
    address public auctioneer;

    function updateAuctioneer(address _auctioneer) public onlyAuctioneer {
        require(_auctioneer != address(0), "The auctioneer must be a valid address");
        auctioneer = _auctioneer;
    }

     
    modifier onlyAuctioneer() {
         
         
         
        require(msg.sender == auctioneer, "Only the auctioneer can nominate a new one");
        _;
    }
}

 

contract TokenWhitelist is AuctioneerManaged {
     
     
     
    mapping(address => bool) public approvedTokens;

    event Approval(address indexed token, bool approved);

     
     
    function getApprovedAddressesOfList(address[] calldata addressesToCheck) external view returns (bool[] memory) {
        uint length = addressesToCheck.length;

        bool[] memory isApproved = new bool[](length);

        for (uint i = 0; i < length; i++) {
            isApproved[i] = approvedTokens[addressesToCheck[i]];
        }

        return isApproved;
    }
    
    function updateApprovalOfToken(address[] memory token, bool approved) public onlyAuctioneer {
        for (uint i = 0; i < token.length; i++) {
            approvedTokens[token[i]] = approved;
            emit Approval(token[i], approved);
        }
    }

}

 

 
 
contract WhitelistPriceOracle is TokenWhitelist, DutchXPriceOracle {
    constructor(DutchX _dutchX, address _ethToken, address _auctioneer)
        DutchXPriceOracle(_dutchX, _ethToken)
        public
    {
        auctioneer = _auctioneer;
    }

    function isWhitelisted(address token) 
        public
        view
        returns (bool) 
    {
        return approvedTokens[token];
    }
}