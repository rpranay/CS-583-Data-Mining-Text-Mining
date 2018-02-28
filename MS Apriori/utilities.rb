$sdc = 0
$must_have = []
$cannot_be_together = []
def parse_input_file(file_path)
  t_s = []
  File.open(file_path, "r") do |f|
    f.each_line do |l|
      l.chomp!
      line = l.split(/{|,|}/)
      line.each do |x|
        x.strip!.to_i
      end
      line.shift
      line.map!(&:to_i)
      t_s.push line
    end
  f.close
  end
  t_s
end

def parse_parameter_file(file_path)
  i_s = []
  mis = Hash.new
  File.open(file_path, "r") do |f|
    f.each_line do |l|
      if l.include? "MIS"
        x1 = l.match(/\([0-9]+\)/).to_s.sub!("(", "").sub!(")", "").to_i
        x2 = l.split('=')[1].strip().to_f
        mis[x1] = x2
        i_s.push(x1)
      elsif l.include? "SDC"
        $sdc = l.split('=')[1].strip().to_f
      elsif l.include? "must-have"
        x1 = l.split(':')[1].split('or')
        x1.each do |x|
          $must_have.push(x.strip().to_i)
        end
      elsif l.include? "cannot_be_together"
        x1 = l.scan(/\{(.*?)\}/)
        x1.each do |x|
          x2 = x[0].split(',')
          (0..x2.length-1).step(1) do |i|
            x2[i] = x2[i].to_i
          end
          $cannot_be_together.push(x2)
        end
      end
    end
  end
  return i_s, mis
end

input = ARGV
if input.length != 2
  puts "Invalid no. of arguments"
  abort
end


$transactions = parse_input_file(input[0])
$itemSet, $misHash = parse_parameter_file(input[1])

def sort_items_with_mis(transactions)
  @item_list = $misHash.keys
  sorted_item_list = @item_list.sort_by {|a| [$misHash[a], a]}
  #print sorted_item_list
  return sorted_item_list
end

def init_pass(sorted_item_list, transactions)
  @support_count = Hash.new 0
  no_of_transactions = transactions.length

  for item_set in transactions
    item_set.each do |item|
      @support_count[item.to_i] += 1
    end
  end

  @init_pass_list = []

  for i in 0..sorted_item_list.length-1
    if (@support_count[sorted_item_list[i]].fdiv(no_of_transactions)) >= $misHash[sorted_item_list[i]]
      @init_pass_list.push(sorted_item_list[i])
      break
    end
  end

  for j in i+1..sorted_item_list.length

    if (@support_count[sorted_item_list[j]].fdiv(no_of_transactions)) >= $misHash[sorted_item_list[i]]
      @init_pass_list.push(sorted_item_list[j])
    end
  end

  return @init_pass_list
end

def freq_one_item_sets(transactions)
  no_of_transactions = transactions.length
  freq_one_item = []
  for l in @init_pass_list
    if (@support_count[l].fdiv(no_of_transactions)) >= $misHash[l]
      freq_one_item.push(l)
    end
  end
  if $must_have.length == 0
    return freq_one_item
  end
  if((freq_one_item & $must_have).length >= 1)
    return (freq_one_item & $must_have)
  end

  return []
end

def support_of(item)
  return @support_count[item].fdiv($transactions.length)
end

def support_count_of(item)
  return @support_count[item]
end

def does_match_unique_last_item_constraint(freq_set_one, freq_set_two)
  freq_set_len = freq_set_one.length
  for i in 0..freq_set_len
    if i == freq_set_len-1
      if freq_set_one[i] == freq_set_two[i]
        return false
      end
    else
      if freq_set_one[i] != freq_set_two[i]
        return false
      end
    end
  end
  return true
end


def is_contained_in_transactions(candidate,transaction)

  if (candidate - transaction).length == 0
    return true
  end
  return false
end

def does_contain_required(item_set)
  if $must_have.length == 0 or ((item_set & $must_have).length >= 1)
    return true
  end
  return false
end

def does_contain_invalid(item_set)

  for i in $cannot_be_together
    #print i
    if (i - item_set).length == 0
      return true
    end
  end
  return false
end

def freq_item_generation(candidate_set)

  @candidate_count = Hash.new 0

  for transaction in $transactions
    for candidate in candidate_set
      if is_contained_in_transactions(candidate,transaction)
        @candidate_count[candidate] += 1
      end
      if is_contained_in_transactions(candidate.drop(1),transaction)
        @candidate_count[candidate.drop(1)] += 1
      end
    end
  end
  @candidate_count
end

sorted_mis_list = sort_items_with_mis($transactions)
init_pass(sorted_mis_list, $transactions)
freq_one_item_sets($transactions)

$count = @support_count
$mis = $misHash
$n = $transactions.length

def level2_candidate_generation(list, sdc)
  c2 = []
  list.each_with_index do |l, l_index|
    support_l = $count[l].fdiv($n)
    if support_l >= $mis[l]
      list.each_with_index do |h, h_index|
        if h_index > l_index
          support_h = $count[h].fdiv($n)
          if support_h >= $mis[l] and (support_h - support_l).abs <= sdc
            c2.push([l,h])
          end
        end
      end
    end
  end
  c2
end


def MS_candidate_generation(frequent_set, sdc)
  ck = []
  len = frequent_set.length
  i = 0
  while i < len
    j = i+1
    while j < len
      if i != j
        x = frequent_set[i] & frequent_set[j]

        if ((frequent_set[i][0..-2] & frequent_set[j][0..-2]) == frequent_set[i][0..-2])

          i_last = frequent_set[i].last
          j_last = frequent_set[j].last
          if i_last != j_last
            support_i = $count[i_last].fdiv($n)
            support_j = $count[j_last].fdiv($n)
            if (support_i - support_j).abs <= sdc
              x.push(i_last)
              x.push(j_last)
              ck.push(x)
              (0..x.length-1).step(1) do |i|
                s = x[0..x.length]
                s.delete(x[i])
                if s.include? x[0] or ($mis[x[1]] == $mis[x[0]])
                  if not frequent_set.include? s
                    ck.delete(x)
                  end
                end
              end
            end
          end
        end
      end
      j += 1
    end
    i += 1
  end

  #print "ck length #{ck.length} \n"
  ck
end

$global_support_count_freq_items = Hash.new 0

def tail_count_of(itemSet)
  count = 0
  for transaction in $transactions
    if is_contained_in_transactions(itemSet,transaction)
      count += 1
    end
  end
  count
end
