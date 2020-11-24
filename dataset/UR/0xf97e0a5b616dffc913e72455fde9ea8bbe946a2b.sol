 

pragma solidity ^0.4.18;



 
 
contract GeneScience {
    bool public isGeneScience = true;

    uint256 internal constant maskLast8Bits = uint256(0xff);
    uint256 internal constant maskFirst248Bits = uint256(~0xff);

    function GeneScience() public {}

     
     
     
     
     
    function _ascend(uint8 trait1, uint8 trait2, uint256 rand) internal pure returns(uint8 ascension) {
        ascension = 0;

        uint8 smallT = trait1;
        uint8 bigT = trait2;

        if (smallT > bigT) {
            bigT = trait1;
            smallT = trait2;
        }

         
        if ((bigT - smallT == 1) && smallT % 2 == 0) {

             
             
             

             
            uint256 maxRand;
            if (smallT < 23) maxRand = 1;
            else maxRand = 0;

            if (rand <= maxRand ) {
                ascension = (smallT / 2) + 16;
            }
        }
    }

     
     
     
     
    function _sliceNumber(uint256 _n, uint256 _nbits, uint256 _offset) private pure returns (uint256) {
         
        uint256 mask = uint256((2**_nbits) - 1) << _offset;
         
        return uint256((_n & mask) >> _offset);
    }

     
     
     
    function _get5Bits(uint256 _input, uint256 _slot) internal pure returns(uint8) {
        return uint8(_sliceNumber(_input, uint256(5), _slot * 5));
    }

     
     
     
    function decode(uint256 _genes) public pure returns(uint8[]) {
        uint8[] memory traits = new uint8[](48);
        uint256 i;
        for(i = 0; i < 48; i++) {
            traits[i] = _get5Bits(_genes, i);
        }
        return traits;
    }

     
    function encode(uint8[] _traits) public pure returns (uint256 _genes) {
        _genes = 0;
        for(uint256 i = 0; i < 48; i++) {
            _genes = _genes << 5;
             
            _genes = _genes | _traits[47 - i];
        }
        return _genes;
    }

     
     
    function expressingTraits(uint256 _genes) public pure returns(uint8[12]) {
        uint8[12] memory express;
        for(uint256 i = 0; i < 12; i++) {
            express[i] = _get5Bits(_genes, i * 4);
        }
        return express;
    }

     
    function mixGenes(uint256 _genes1, uint256 _genes2, uint256 _targetBlock) public returns (uint256) {
        require(block.number > _targetBlock);

         
         
         
         
        uint256 randomN = uint256(block.blockhash(_targetBlock));

        if (randomN == 0) {
             
             
             
             
             
             
             
            _targetBlock = (block.number & maskFirst248Bits) + (_targetBlock & maskLast8Bits);

             
             
            if (_targetBlock >= block.number) _targetBlock -= 256;

            randomN = uint256(block.blockhash(_targetBlock));

             
             
             
             
        }

         
         
        randomN = uint256(keccak256(randomN, _genes1, _genes2, _targetBlock));
        uint256 randomIndex = 0;

        uint8[] memory genes1Array = decode(_genes1);
        uint8[] memory genes2Array = decode(_genes2);
         
        uint8[] memory babyArray = new uint8[](48);
         
        uint256 traitPos;
         
        uint8 swap;
         
        for(uint256 i = 0; i < 12; i++) {
             
            uint256 j;
             
            uint256 rand;
            for(j = 3; j >= 1; j--) {
                traitPos = (i * 4) + j;

                rand = _sliceNumber(randomN, 2, randomIndex);  
                randomIndex += 2;

                 
                if (rand == 0) {
                     
                    swap = genes1Array[traitPos];
                    genes1Array[traitPos] = genes1Array[traitPos - 1];
                    genes1Array[traitPos - 1] = swap;

                }

                rand = _sliceNumber(randomN, 2, randomIndex);  
                randomIndex += 2;

                if (rand == 0) {
                     
                    swap = genes2Array[traitPos];
                    genes2Array[traitPos] = genes2Array[traitPos - 1];
                    genes2Array[traitPos - 1] = swap;
                }
            }

        }

         
         
         

         
         
         
         
         

         
         
         
        for(traitPos = 0; traitPos < 48; traitPos++) {

             
            uint8 ascendedTrait = 0;

             
             
             
             
             
             
             
             
             
             
            if ((traitPos % 4 == 0) && (genes1Array[traitPos] & 1) != (genes2Array[traitPos] & 1)) {
                rand = _sliceNumber(randomN, 3, randomIndex);
                randomIndex += 3;

                ascendedTrait = _ascend(genes1Array[traitPos], genes2Array[traitPos], rand);
            }

            if (ascendedTrait > 0) {
                babyArray[traitPos] = uint8(ascendedTrait);
            } else {
                 
                 
                 
                rand = _sliceNumber(randomN, 1, randomIndex);
                randomIndex += 1;

                if (rand == 0) {
                    babyArray[traitPos] = uint8(genes1Array[traitPos]);
                } else {
                    babyArray[traitPos] = uint8(genes2Array[traitPos]);
                }
            }
        }

        return encode(babyArray);
    }
}