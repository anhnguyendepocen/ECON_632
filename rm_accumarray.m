%%Created by RM on 2019.01.19 for ECON 632 PS 1


function output_mat = rm_accumarray(rm_subs,rm_vals)

max_row = max(rm_subs(:,1));
max_col = max(rm_subs(:,2));
output_mat = zeros(max_row,max_col);

    for i = 1:rows(rm_subs)
        val_use = rm_vals(1,i);

        output_row = rm_subs(i,1);
        output_col = rm_subs(i,2);

        output_mat(output_row,output_col) = output_mat(output_row,output_col) + val_use;

    end;

%end;