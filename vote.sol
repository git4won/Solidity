pragma solidity ^0.4.11;

contract Ballot {

    // 投票人
    struct Voter {
        uint weight;         // 权重
        bool voted;          // 是否已投票    
        address delegate;    // 受委托人的账户地址
        uint vote;           // 投票选择（提案索引）
    }


    // 提案
    struct Proposal {
        bytes32 name;        // 提案名称
        uint voteCount;      // 获得票数
    }


    // 状态变量
    // 将以下关键状态信息设置为 public 能够增加投票的公平性和透明性。
    address public chairperson;               // 投票发起人
    mapping(address => Voter) public voters;  // 所有投票人，address 到 Voter 的映射
    Proposal[] public proposals;              // 所有提案，动态大小的 Proposal 数组


    // Create a new ballot to choose one of `proposalNames`
    // 创建提案
    // 消息的调用者即为投票发起人
    function Ballot(bytes32[] proposalNames) {
        chairperson = msg.sender;
        voters[chairperson].weight = 1;

        for (uint i = 0; i < proposalNames.length; i++) {
            proposals.push(Proposal({
                name: proposalNames[i],
                voteCount: 0
            }));
        }
    }


    // Give `voter` the right to vote on this ballot.
    // May only be called by `chairperson`.
    // 赋予投票权，即投票权重设为 1
    // 使用 require 限定只有投票发起人可以调用该函数
    // 如果 require 中表达式结果为 false，这次调用会中止，
    // 且回滚所有状态和以太币余额的改变到调用前。但已消耗的 Gas 不会返还。
    function giveRightToVote(address voter) {
        require(msg.sender == chairperson && !voters[voter].voted);
        voters[voter].weight = 1;
    }


    // Delegate your vote to the voter `to`.
    // 委托投票权
    // 用 require 确保发起人没有投过票，且不是委托给自己。
    // 因为被委托人也可能将投票委托出去，所以用 while 循环查找最终的投票代表。
    // 找到后，如果被委托人已投票，则将委托人的权重加到所投的提案上；
    // 如果被委托人还未投票，则将委托人的权重加到被委托人的权重上。
    function delegate(address to) {
        Voter sender = voters[msg.sender];
        require(!sender.voted);
        require(to != msg.sender);

        while (voters[to].delegate != address(0)) {
            to = voters[to].delegate;
            
            // We found a loop in the delegation, not allowed.
            require(to != msg.sender);
        }

        sender.voted = true;
        sender.delegate = to;
        Voter delegate = voters[to];
        if (delegate.voted) {
            proposals[delegate.vote].voteCount += sender.weight;
        } else {
            delegate.weight += sender.weight;
        }
    }
    

    // Give your vote (including votes delegated to you)
    // to proposal `proposals[proposal].name`.
    // 投票
    function vote(uint proposal) {
        Voter sender = voters[msg.sender];
        require(!sender.voted);
        sender.voted = true;
        sender.vote = proposal;

        proposals[proposal].voteCount += sender.weight;
    }


    // Computes the winning proposal taking all
    // previous votes into account
    // 查询获胜提案索引
    // constant 表示该函数不会改变合约状态变量的值。
    function winningProposal() constant returns (uint winningProposal) {
        uint winningVoteCount = 0;
        for (uint p = 0; p < proposals.length; p++) {
            if (proposals[p].voteCount > winningVoteCount) {
                winningVoteCount = proposals[p].voteCount;
                winningProposal = p;
            }
        }
    }


    // Call winningProposal() function to get the index
    // of the winner contained in the proposals array and then
    // returns the name of the winner
    // 通过内部调用 winningProposal() 函数的方式获得获胜提案。
    // 如果需要采用外部调用，则需要写为 this.winningProposal()。
    function winnerName() constant returns (bytes32 winnerName) {
        winnerName = proposals[winningProposal()].name;
    }

}

