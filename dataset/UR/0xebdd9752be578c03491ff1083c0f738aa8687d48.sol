 
    function claimAllPendingReward(uint records) public isMemberAndcheckPause {
        _claimRewardToBeDistributed(records);
        _claimStakeCommission(records);
        tf.unlockStakerUnlockableTokens(msg.sender); 
        uint gvReward = gv.claimReward(msg.sender, records);
        if (gvReward > 0) {
            require(tk.transfer(msg.sender, gvReward));
        }
    }

     
    function getAllPendingRewardOfUser(address _add) public view returns(uint total) {
        uint caReward = getRewardToBeDistributedByUser(_add);
        uint commissionEarned = td.getStakerTotalEarnedStakeCommission(_add);
        uint commissionReedmed = td.getStakerTotalReedmedStakeCommission(_add);
        uint unlockableStakedTokens = tf.getStakerAllUnlockableStakedTokens(_add);
        uint governanceReward = gv.getPendingReward(_add);
        total = caReward.add(unlockableStakedTokens).add(commissionEarned.
        sub(commissionReedmed)).add(governanceReward);
    }

     
     
     
    function _rewardAgainstClaim(uint claimid, uint coverid, uint sumAssured, uint status) internal {
        uint premiumNXM = qd.getCoverPremiumNXM(coverid);
        bytes4 curr = qd.getCurrencyOfCover(coverid);
        uint distributableTokens = premiumNXM.mul(cd.claimRewardPerc()).div(100); 
            
        uint percCA;
        uint percMV;

        (percCA, percMV) = cd.getRewardStatus(status);
        cd.setClaimRewardDetail(claimid, percCA, percMV, distributableTokens);
        if (percCA > 0 || percMV > 0) {
            tc.mint(address(this), distributableTokens);
        }

        if (status == 6 || status == 9 || status == 11) {
            cd.changeFinalVerdict(claimid, -1);
            td.setDepositCN(coverid, false);  
            tf.burnDepositCN(coverid);  
            
            pd.changeCurrencyAssetVarMin(curr, pd.getCurrencyAssetVarMin(curr).sub(sumAssured));
            p2.internalLiquiditySwap(curr);
            
        } else if (status == 7 || status == 8 || status == 10) {
            cd.changeFinalVerdict(claimid, 1);
            td.setDepositCN(coverid, false);  
            tf.unlockCN(coverid);
            p1.sendClaimPayout(coverid, claimid, sumAssured, qd.getCoverMemberAddress(coverid), curr);  
        } 
    }

     
    function _changeClaimStatusCA(uint claimid, uint coverid, uint status) internal {
         
        if (c1.checkVoteClosing(claimid) == 1) {
            uint caTokens = c1.getCATokens(claimid, 0);  
            uint accept;
            uint deny;
            uint acceptAndDeny;
            bool rewardOrPunish;
            uint sumAssured;
            (, accept) = cd.getClaimVote(claimid, 1);
            (, deny) = cd.getClaimVote(claimid, -1);
            acceptAndDeny = accept.add(deny);
            accept = accept.mul(100);
            deny = deny.mul(100);

            if (caTokens == 0) {
                status = 3;
            } else {
                sumAssured = qd.getCoverSumAssured(coverid).mul(DECIMAL1E18);
                 
                if (caTokens > sumAssured.mul(5)) {

                    if (accept.div(acceptAndDeny) > 70) {
                        status = 7;
                        qd.changeCoverStatusNo(coverid, uint8(QuotationData.CoverStatus.ClaimAccepted));
                        rewardOrPunish = true;
                    } else if (deny.div(acceptAndDeny) > 70) {
                        status = 6;
                        qd.changeCoverStatusNo(coverid, uint8(QuotationData.CoverStatus.ClaimDenied));
                        rewardOrPunish = true;
                    } else if (accept.div(acceptAndDeny) > deny.div(acceptAndDeny)) {
                        status = 4;
                    } else {
                        status = 5;
                    }

                } else {

                    if (accept.div(acceptAndDeny) > deny.div(acceptAndDeny)) {
                        status = 2;
                    } else {
                        status = 3;
                    }
                }
            }

            c1.setClaimStatus(claimid, status);

            if (rewardOrPunish)
                _rewardAgainstClaim(claimid, coverid, sumAssured, status);
        }
    }

     
    function _changeClaimStatusMV(uint claimid, uint coverid, uint status) internal {

         
        if (c1.checkVoteClosing(claimid) == 1) {
            uint8 coverStatus;
            uint statusOrig = status;
            uint mvTokens = c1.getCATokens(claimid, 1);  

             
            uint sumAssured = qd.getCoverSumAssured(coverid).mul(DECIMAL1E18);
            uint thresholdUnreached = 0;
             
             
            if (mvTokens < sumAssured.mul(5))
                thresholdUnreached = 1;

            uint accept;
            (, accept) = cd.getClaimMVote(claimid, 1);
            uint deny;
            (, deny) = cd.getClaimMVote(claimid, -1);

            if (accept.add(deny) > 0) {
                if (accept.mul(100).div(accept.add(deny)) >= 50 && statusOrig > 1 && 
                    statusOrig <= 5 && thresholdUnreached == 0) {
                    status = 8;
                    coverStatus = uint8(QuotationData.CoverStatus.ClaimAccepted);
                } else if (deny.mul(100).div(accept.add(deny)) >= 50 && statusOrig > 1 &&
                    statusOrig <= 5 && thresholdUnreached == 0) {
                    status = 9;
                    coverStatus = uint8(QuotationData.CoverStatus.ClaimDenied);
                }
            }
            
            if (thresholdUnreached == 1 && (statusOrig == 2 || statusOrig == 4)) {
                status = 10;
                coverStatus = uint8(QuotationData.CoverStatus.ClaimAccepted);
            } else if (thresholdUnreached == 1 && (statusOrig == 5 || statusOrig == 3 || statusOrig == 1)) {
                status = 11;
                coverStatus = uint8(QuotationData.CoverStatus.ClaimDenied);
            }

            c1.setClaimStatus(claimid, status);
            qd.changeCoverStatusNo(coverid, uint8(coverStatus));
             
            _rewardAgainstClaim(claimid, coverid, sumAssured, status);
        }
    }

     
    function _claimRewardToBeDistributed(uint _records) internal {
        uint lengthVote = cd.getVoteAddressCALength(msg.sender);
        uint voteid;
        uint lastIndex;
        (lastIndex, ) = cd.getRewardDistributedIndex(msg.sender);
        uint total = 0;
        uint tokenForVoteId = 0;
        bool lastClaimedCheck;
        uint _days = td.lockCADays();
        bool claimed;   
        uint counter = 0;
        uint claimId;
        uint perc;
        uint i;
        uint lastClaimed = lengthVote;

        for (i = lastIndex; i < lengthVote && counter < _records; i++) {
            voteid = cd.getVoteAddressCA(msg.sender, i);
            (tokenForVoteId, lastClaimedCheck, , perc) = getRewardToBeGiven(1, voteid, 0);
            if (lastClaimed == lengthVote && lastClaimedCheck == true)
                lastClaimed = i;
            (, claimId, , claimed) = cd.getVoteDetails(voteid);

            if (perc > 0 && !claimed) {
                counter++;
                cd.setRewardClaimed(voteid, true);
            } else if (perc == 0 && cd.getFinalVerdict(claimId) != 0 && !claimed) {
                (perc, , ) = cd.getClaimRewardDetail(claimId);
                if (perc == 0)
                    counter++;
                cd.setRewardClaimed(voteid, true);
            }
            if (tokenForVoteId > 0)
                total = tokenForVoteId.add(total);
        }
        if(lastClaimed == lengthVote)
            cd.setRewardDistributedIndexCA(msg.sender, i);
        else
            cd.setRewardDistributedIndexCA(msg.sender, lastClaimed);
        lengthVote = cd.getVoteAddressMemberLength(msg.sender);
        lastClaimed = lengthVote;
        _days = _days.mul(counter);
        if (tc.tokensLockedAtTime(msg.sender, "CLA", now) > 0)
            tc.reduceLock(msg.sender, "CLA", _days);
        (, lastIndex) = cd.getRewardDistributedIndex(msg.sender);
        lastClaimed = lengthVote;
        counter = 0;
        for (i = lastIndex; i < lengthVote && counter < _records; i++) {
            voteid = cd.getVoteAddressMember(msg.sender, i);
            (tokenForVoteId, lastClaimedCheck, , ) = getRewardToBeGiven(0, voteid, 0);
            if (lastClaimed == lengthVote && lastClaimedCheck == true)
                lastClaimed = i;
            (, claimId, , claimed) = cd.getVoteDetails(voteid);
            if (claimed == false && cd.getFinalVerdict(claimId) != 0){
                cd.setRewardClaimed(voteid, true);
                counter++;
            }
            if (tokenForVoteId > 0)
                total = tokenForVoteId.add(total);
        }
        if (total > 0)
            require(tk.transfer(msg.sender, total));
        if(lastClaimed == lengthVote) 
            cd.setRewardDistributedIndexMV(msg.sender, i);
        else
            cd.setRewardDistributedIndexMV(msg.sender, lastClaimed);
    }

     
    function _claimStakeCommission(uint _records) internal {
        uint total=0;
        uint len = td.getStakerStakedContractLength(msg.sender);
        uint lastCompletedStakeCommission = td.lastCompletedStakeCommission(msg.sender);
        uint commissionEarned;
        uint commissionRedeemed;
        uint maxCommission;
        uint lastCommisionRedeemed = len;
        uint counter;
        uint i;

        for (i = lastCompletedStakeCommission; i < len && counter < _records; i++) {
            commissionRedeemed = td.getStakerRedeemedStakeCommission(msg.sender, i);
            commissionEarned = td.getStakerEarnedStakeCommission(msg.sender, i);
            maxCommission = td.getStakerInitialStakedAmountOnContract(
                msg.sender, i).mul(td.stakerMaxCommissionPer()).div(100);
            if (lastCommisionRedeemed == len && maxCommission != commissionEarned)
                lastCommisionRedeemed = i;
            td.pushRedeemedStakeCommissions(msg.sender, i, commissionEarned.sub(commissionRedeemed));
            total = total.add(commissionEarned.sub(commissionRedeemed));
            counter++;
        }
            if(lastCommisionRedeemed == len)
                td.setLastCompletedStakeCommissionIndex(msg.sender, i);
            else
                td.setLastCompletedStakeCommissionIndex(msg.sender, lastCommisionRedeemed); 

        if (total > 0) 
            require(tk.transfer(msg.sender, total));  
        
    }
}
