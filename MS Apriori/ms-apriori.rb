
require "./utilities"

def ms_apriori
  @output = ""
  transactions = $transactions
  sorted_item_list = sort_items_with_mis(transactions)
  list_L = init_pass(sorted_item_list, transactions)
  freq_one_item = freq_one_item_sets(transactions)

  @output += "Frequent 1-itemsets\n\n"

  for id in @support_count.keys
    $global_support_count_freq_items[[id]] = @support_count[id]
  end
  for x in freq_one_item
      @output += "     #{@support_count[x]} : {#{x}}\n"
    end
    @output += "     Total number of frequent 1-itemsets = #{freq_one_item.length}\n\n"
  curr_freq_set = freq_one_item
  @global_freq_set = []
  @global_freq_set.push(curr_freq_set)
  @support_count_freq_items = {}
  k = 2
  while curr_freq_set.length > 0
    if k == 2
      curr_candidate_k = level2_candidate_generation(list_L, $sdc)
      ##print "---== #{curr_candidate_k.length} \n"
    else
      curr_candidate_k = MS_candidate_generation(curr_freq_set,$sdc)
      #print "---==>>>> #{curr_candidate_k} \n"

    end

    @support_count_freq_items = freq_item_generation(curr_candidate_k)

    curr_freq_set = fk_generation(curr_candidate_k)
    #print("888 #{curr_freq_set}")
    #print("\n")

    @global_freq_set.push(curr_freq_set)
    if curr_freq_set.length > 0
      @output += "Frequent #{k}-itemsets\n\n"
    end
    #print "-- #{$global_support_count_freq_items} \n"
    count = 0
    for x in curr_freq_set
      if ($must_have.length == 0 or (x - $must_have).length != x.length) and does_contain_invalid(x) == false
      count += 1
      @output += "     #{@support_count_freq_items[x]} : {"
      $global_support_count_freq_items[x] = @support_count_freq_items[x]
      for y in x
        @output += "#{y},"
      end
      @output = @output[0..-2]
      @output += "}\n"
      @output += "Tailcount = #{tail_count_of(x[1..-1])}\n"
      end
    end
    if count > 0
      @output += "\n     Total number of frequent #{k}-itemsets = #{count}\n\n"
    else
      @output.sub!("Frequent #{k}-itemsets\n\n", "")
    end

    k += 1
    #curr_freq_set = []
  end
end

def fk_generation(candidate_k)
  no_of_transactions = $transactions.length
  freq_item_set = []
  for c in candidate_k
    if (@support_count_freq_items[c].fdiv(no_of_transactions)) >= $misHash[c[0]]
      freq_item_set.push(c)
    end
  end
  return freq_item_set

end

ms_apriori
@output += "...."
print "\n ******  Frequent items are successfully generated for your inputs. Please Check the output.txt file  **** \n"


File.open("Data/output.txt", 'w') { |file| file.write(@output) }
